import {randomUUID} from "node:crypto";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";

import {type DocumentReference, FieldValue, type WriteBatch} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {onObjectFinalized} from "firebase-functions/v2/storage";

import {bucket, db} from "../lib/admin.js";
import {
  ANALYSIS_MAX_INSTANCES,
  ANALYSIS_MEMORY,
  ANALYSIS_STATUS,
  ANALYSIS_TIMEOUT_SECONDS,
  BATCH_LIMIT,
  F,
  FEEDBACK,
  OFFICIAL,
  RECORDINGS,
  REGION,
  STORAGE_BUCKET,
  VOICE,
} from "../lib/constants.js";
import {analyseFile} from "../lib/analyse_file.js";
import {AudioToolError, encodePlayback} from "../lib/ffmpeg.js";
import {parseRecordingUpload, playbackPathFor, type RecordingUpload} from "../lib/recording_files.js";
import {type VoiceAnalysis} from "../lib/voice_analysis.js";
import {mergeStemsUpload} from "./merge_stems.js";

/**
 * onRecordingUploaded: when the audio of an official recording arrives at
 * `recordings/{studentId}/{recordingId}.{ext}`, finds every place the
 * sheikh spoke (his channel is the right one, lib/voice_analysis.ts) and
 * writes one `voice` feedback marker per place, makes the centred copy
 * `{recordingId}.play.mp3` for listening, and fills `analysis`,
 * `playbackPath` and `durationSec`.
 *
 * The left / right channels are found by the analysis itself (swapped
 * ones are swapped back, `analysis.swapped`), and the student's bleed in
 * the sheikh's microphone is never taken for the sheikh.
 *
 * A two-file recording (source "stems") uploads `{recordingId}.student.{ext}`
 * and `{recordingId}.sheikh.{ext}` instead: once both are there, they are
 * joined into the stereo file at its storagePath (merge_stems.ts), whose
 * arrival then runs this same analysis.
 *
 * Practice recordings are not analysed (phones record one channel), and
 * `.play.mp3` copies and other objects are ignored. Safe to run again
 * (triggers are delivered at least once): the old voice markers are
 * replaced, written notes are kept. Any failure leaves `analysis.status`
 * 'failed' and the original file playable.
 */
export const onRecordingUploaded = onObjectFinalized(
  {
    region: REGION,
    bucket: STORAGE_BUCKET,
    memory: ANALYSIS_MEMORY,
    timeoutSeconds: ANALYSIS_TIMEOUT_SECONDS,
    maxInstances: ANALYSIS_MAX_INSTANCES,
  },
  async (event) => {
    const upload = parseRecordingUpload(event.data.name);
    if (!upload) return;
    if (upload.stem) await mergeStemsUpload(upload.stem, upload, event.data.name);
    else await analyseUpload(upload, event.data.name);
  },
);

/** The gRPC status of a Firestore write to a missing document. */
const GRPC_NOT_FOUND = 5;

/** What the analysis found, for the recording document; [voices] is null for a mono file. */
interface Result {
  voices: VoiceAnalysis | null;
  durationSec: number;
}

async function analyseUpload(upload: RecordingUpload, objectPath: string): Promise<void> {
  const {studentId, recordingId} = upload;
  const ref = db.collection(RECORDINGS).doc(recordingId);
  const snapshot = await ref.get();
  if (!snapshot.exists) {
    // The upload raced a delete (failed upload cleaned up, recording
    // deleted): nothing will ever point at this file.
    logger.info("Uploaded file has no recording; deleting it.", {objectPath});
    await bucket.file(objectPath).delete({ignoreNotFound: true});
    return;
  }
  if (snapshot.get(F.storagePath) !== objectPath || snapshot.get(F.studentId) !== studentId) {
    logger.warn("Uploaded file is not its recording's storagePath; ignored.", {objectPath});
    return;
  }
  if (snapshot.get(F.type) !== OFFICIAL) return;

  // A two-file recording: how its stems lined up, kept through every state.
  const lag = snapshot.get(`${F.analysis}.stemsLagMs`);
  const carried = typeof lag === "number" ? {stemsLagMs: lag} : {};

  try {
    await ref.update({[F.analysis]: {status: ANALYSIS_STATUS.pending, ...carried}});
  } catch (error) {
    // Deleted a moment ago: onRecordingDeleted removes the file.
    if ((error as {code?: unknown}).code === GRPC_NOT_FOUND) return;
    throw error;
  }

  const workDir = await mkdtemp(join(tmpdir(), "recording-"));
  const playbackPath = playbackPathFor(studentId, recordingId);
  try {
    const original = join(workDir, "original");
    const playback = join(workDir, "playback.mp3");
    await bucket.file(objectPath).download({destination: original});

    const {voices: found, durationSeconds} = await analyseFile(original);
    const result: Result = {voices: found, durationSec: Math.round(durationSeconds)};

    await encodePlayback(original, playback);
    await bucket.upload(playback, {
      destination: playbackPath,
      contentType: "audio/mpeg",
      // getDownloadURL() needs a token on the object.
      metadata: {metadata: {firebaseStorageDownloadTokens: randomUUID()}},
    });

    await writeResult(ref, snapshot.get(F.teacherId) as string, result, playbackPath, carried);
    const voices = result.voices;
    logger.info("Recording analysed.", {
      recordingId,
      status: voices ? ANALYSIS_STATUS.done : ANALYSIS_STATUS.mono,
      swapped: voices?.swapped,
      bleedDb: voices?.bleedDb,
      separationDb: voices?.separationDb,
      segmentCount: voices?.segments.length ?? 0,
      segments: voices?.segments ?? [],
      durationSec: result.durationSec,
    });
  } catch (error) {
    await recordFailure(ref, playbackPath, error, carried);
  } finally {
    await rm(workDir, {recursive: true, force: true});
  }
}

/**
 * Replaces the recording's voice markers with [result]'s and updates the
 * recording, in batches of at most 500 writes; the recording's own update
 * goes in the last one. Written notes are left alone.
 */
async function writeResult(
  ref: DocumentReference,
  teacherId: string,
  result: Result,
  playbackPath: string,
  carried: Record<string, unknown>,
): Promise<void> {
  const feedback = ref.collection(FEEDBACK);
  const oldMarkers = await feedback.where(F.kind, "==", VOICE).select().get();

  const segments = result.voices?.segments ?? [];
  const writes: Array<(batch: WriteBatch) => void> = [
    ...oldMarkers.docs.map((doc) => (batch: WriteBatch) => batch.delete(doc.ref)),
    ...segments.map((segment) => (batch: WriteBatch) =>
      batch.create(feedback.doc(), {
        [F.teacherId]: teacherId,
        [F.kind]: VOICE,
        [F.note]: "",
        [F.atSecond]: Math.floor(segment.start),
        // Never before the start: a short segment inside one second.
        [F.endSecond]: Math.max(Math.floor(segment.start), Math.round(segment.end)),
        [F.createdAt]: FieldValue.serverTimestamp(),
      }),
    ),
  ];
  const segmentCount = segments.length;
  const voices = result.voices;
  writes.push((batch) =>
    batch.update(ref, {
      [F.analysis]: voices
        ? {
            status: ANALYSIS_STATUS.done,
            segmentCount,
            swapped: voices.swapped,
            bleedDb: voices.bleedDb,
            separationDb: voices.separationDb,
            ...carried,
          }
        : {status: ANALYSIS_STATUS.mono, ...carried},
      [F.playbackPath]: playbackPath,
      [F.durationSec]: result.durationSec,
      ...(segmentCount > 0 ? {[F.unreadFeedback]: true} : {}),
    }),
  );

  for (let start = 0; start < writes.length; start += BATCH_LIMIT) {
    const batch = db.batch();
    for (const write of writes.slice(start, start + BATCH_LIMIT)) write(batch);
    await batch.commit();
  }
}

/**
 * Marks the analysis failed. If the recording was deleted meanwhile, the
 * playback copy and markers this run may have written are removed instead
 * (onRecordingDeleted already ran and could not see them).
 */
async function recordFailure(
  ref: DocumentReference,
  playbackPath: string,
  error: unknown,
  carried: Record<string, unknown>,
): Promise<void> {
  const code = error instanceof AudioToolError ? error.code : "internal";
  if (!(await ref.get()).exists) {
    logger.info("Recording deleted during its analysis; cleaning up.", {recordingId: ref.id});
    await Promise.all([
      bucket.file(playbackPath).delete({ignoreNotFound: true}),
      db.recursiveDelete(ref.collection(FEEDBACK)),
    ]);
    return;
  }
  logger.error("Recording analysis failed.", {recordingId: ref.id, code, error: String(error)});
  await ref.update({[F.analysis]: {status: ANALYSIS_STATUS.failed, error: code, ...carried}});
}
