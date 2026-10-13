// The two-file half of onRecordingUploaded: when both stems of a recording
// (source "stems") are in the bucket, joins them into the stereo file at
// its storagePath. That upload then runs the normal analysis
// (on_recording_uploaded.ts), so markers and playback have one code path.
import {randomUUID} from "node:crypto";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";

import type {DocumentReference} from "firebase-admin/firestore";
import {logger} from "firebase-functions";

import {bucket, db} from "../lib/admin.js";
import {ANALYSIS_STATUS, F, OFFICIAL, RECORDINGS, SOURCE} from "../lib/constants.js";
import {AudioToolError, decodeEnvelope, joinStems} from "../lib/ffmpeg.js";
import {isRecordingFilePath, type RecordingUpload, type StemRole, stemPathsOf} from "../lib/recording_files.js";
import {checkStems} from "../lib/stems.js";

/** The gRPC status of a Firestore write to a missing document. */
const GRPC_NOT_FOUND = 5;

/**
 * analysis.status values after which a stem's trigger has nothing to do:
 * the stems are being joined, or were (the joined file's analysis runs or
 * ran). A failed join may be tried again.
 */
const CLAIMED_STATUSES: readonly string[] = [
  ANALYSIS_STATUS.merging,
  ANALYSIS_STATUS.pending,
  ANALYSIS_STATUS.done,
  ANALYSIS_STATUS.mono,
];

/**
 * Handles the [stem] of [upload] arriving at [objectPath]. Waits (returns)
 * until the other stem is there too; then exactly one trigger claims the
 * join (triggers are delivered at least once, and both stems may finish
 * at the same moment), checks that the stems are of the same session,
 * joins them (student LEFT, sheikh RIGHT, MP3 320k), uploads the result to
 * the recording's storagePath and deletes the stems. A failure leaves
 * `analysis.status` 'failed' with a `stems_` error and keeps the stems.
 */
export async function mergeStemsUpload(stem: StemRole, upload: RecordingUpload, objectPath: string): Promise<void> {
  const {studentId, recordingId} = upload;
  const ref = db.collection(RECORDINGS).doc(recordingId);
  const snapshot = await ref.get();
  if (!snapshot.exists) {
    // The upload raced a delete: nothing will ever point at this file.
    logger.info("Uploaded stem has no recording; deleting it.", {objectPath});
    await bucket.file(objectPath).delete({ignoreNotFound: true});
    return;
  }
  const stems = stemPathsOf(snapshot.get(F.stemPaths), recordingId);
  const storagePath = snapshot.get(F.storagePath);
  if (
    snapshot.get(F.source) !== SOURCE.stems ||
    snapshot.get(F.type) !== OFFICIAL ||
    snapshot.get(F.studentId) !== studentId ||
    stems[stem] !== objectPath ||
    !stems.student ||
    !stems.sheikh ||
    !isRecordingFilePath(storagePath, recordingId)
  ) {
    logger.warn("Uploaded stem is not one of its recording's stemPaths; ignored.", {objectPath});
    return;
  }
  const paths = {student: stems.student, sheikh: stems.sheikh};

  const other = stem === "student" ? paths.sheikh : paths.student;
  if (!(await bucket.file(other).exists())[0]) {
    logger.info("Stem arrived; waiting for the other one.", {recordingId, stem});
    return;
  }
  if (!(await claimStemsJoin(ref))) {
    logger.info("Stems already joined or being joined.", {recordingId, stem});
    return;
  }

  const workDir = await mkdtemp(join(tmpdir(), "stems-"));
  let lagMs: number | null = null;
  try {
    const studentFile = join(workDir, "student");
    const sheikhFile = join(workDir, "sheikh");
    await Promise.all([
      bucket.file(paths.student).download({destination: studentFile}),
      bucket.file(paths.sheikh).download({destination: sheikhFile}),
    ]);
    const [student, sheikh] = await Promise.all([decodeEnvelope(studentFile), decodeEnvelope(sheikhFile)]);
    const check = checkStems(student, sheikh);
    lagMs = check.alignment?.lagMs ?? null;
    logger.info("Stems checked.", {
      recordingId,
      studentSeconds: student.durationSeconds,
      sheikhSeconds: sheikh.durationSeconds,
      lagMs,
      correlation: check.alignment?.correlation,
      problem: check.problem,
    });
    if (check.problem) {
      await ref.update({[F.analysis]: failure(check.problem, lagMs)});
      return;
    }

    const merged = join(workDir, "merged.mp3");
    await joinStems(studentFile, sheikhFile, Math.max(student.durationSeconds, sheikh.durationSeconds), merged);
    // Written before the upload: the joined file's analysis keeps it.
    await ref.update({[F.analysis]: {status: ANALYSIS_STATUS.merging, ...lagField(lagMs)}});
    await bucket.upload(merged, {
      destination: storagePath,
      contentType: "audio/mpeg",
      // getDownloadURL() needs a token on the object.
      metadata: {metadata: {firebaseStorageDownloadTokens: randomUUID()}},
    });
    logger.info("Stems joined.", {recordingId, storagePath});
  } catch (error) {
    await recordFailure(ref, paths, storagePath, lagMs, error);
    return;
  } finally {
    await rm(workDir, {recursive: true, force: true});
  }

  // Joined: the stems are not needed any more (Storage grows otherwise).
  // Not a failure if this fails: onRecordingDeleted removes them later.
  try {
    await Promise.all([
      bucket.file(paths.student).delete({ignoreNotFound: true}),
      bucket.file(paths.sheikh).delete({ignoreNotFound: true}),
    ]);
  } catch (error) {
    logger.warn("Could not delete the joined stems.", {recordingId, error: String(error)});
  }
}

/**
 * Sets analysis.status to 'merging' unless another trigger already did (or
 * the stems were joined); true when this trigger may join them. Exported
 * for the tests.
 */
export function claimStemsJoin(ref: DocumentReference): Promise<boolean> {
  return db.runTransaction(async (transaction) => {
    const doc = await transaction.get(ref);
    if (!doc.exists) return false;
    const status = doc.get(`${F.analysis}.status`);
    if (CLAIMED_STATUSES.includes(status)) return false;
    transaction.update(ref, {[F.analysis]: {status: ANALYSIS_STATUS.merging}});
    return true;
  });
}

const lagField = (lagMs: number | null) => (lagMs === null ? {} : {stemsLagMs: lagMs});

const failure = (error: string, lagMs: number | null) => ({
  status: ANALYSIS_STATUS.failed,
  error,
  ...lagField(lagMs),
});

/**
 * Marks the join failed (`stems_decode`, `stems_encode` or
 * `stems_internal`). If the recording was deleted meanwhile, removes what
 * this run may have left: onRecordingDeleted already ran.
 */
async function recordFailure(
  ref: DocumentReference,
  stems: Record<StemRole, string>,
  storagePath: string,
  lagMs: number | null,
  error: unknown,
): Promise<void> {
  const code = `stems_${error instanceof AudioToolError ? error.code : "internal"}`;
  const deleted = (error as {code?: unknown}).code === GRPC_NOT_FOUND || !(await ref.get()).exists;
  if (deleted) {
    logger.info("Recording deleted while its stems were joined; cleaning up.", {recordingId: ref.id});
    await Promise.all(
      [stems.student, stems.sheikh, storagePath].map((path) => bucket.file(path).delete({ignoreNotFound: true})),
    );
    return;
  }
  logger.error("Joining the stems failed.", {recordingId: ref.id, code, error: String(error)});
  await ref.update({[F.analysis]: failure(code, lagMs)});
}
