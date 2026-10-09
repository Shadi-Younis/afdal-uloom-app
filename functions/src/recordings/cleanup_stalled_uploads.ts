import {Timestamp} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {onSchedule} from "firebase-functions/v2/scheduler";

import {bucket, db} from "../lib/admin.js";
import {deleteInBatches} from "../lib/batch.js";
import {
  CLEANUP_SCHEDULE,
  CLEANUP_TIME_ZONE,
  F,
  RECORDINGS,
  STALLED_UPLOAD_AGE_MS,
} from "../lib/constants.js";
import {RECORDINGS_PREFIX, findStalledRecordings} from "../lib/recording_files.js";

export interface CleanupResult {
  /** Recordings old enough to be checked. */
  checked: number;
  /** Of those, the ones without their audio file, now deleted. */
  deleted: number;
}

/**
 * cleanupStalledUploads (daily): deletes recordings older than 24 h whose
 * audio file does not exist, i.e. uploads that failed without the app
 * deleting the document. onRecordingDeleted then removes their feedback.
 */
export const cleanupStalledUploads = onSchedule(
  {schedule: CLEANUP_SCHEDULE, timeZone: CLEANUP_TIME_ZONE},
  async () => {
    const result = await runStalledUploadCleanup(new Date());
    logger.info("Stalled uploads cleaned up.", result);
  },
);

/** The cleanup itself, as of [now]; separate from the scheduler for tests. */
export async function runStalledUploadCleanup(now: Date): Promise<CleanupResult> {
  const cutoff = Timestamp.fromMillis(now.getTime() - STALLED_UPLOAD_AGE_MS);
  const old = await db
    .collection(RECORDINGS)
    .where(F.createdAt, "<=", cutoff)
    .select(F.storagePath, F.createdAt)
    .get();
  if (old.empty) return {checked: 0, deleted: 0};

  // One listing of the bucket instead of one request per recording. Listed
  // after the query, so a file that finished uploading meanwhile counts.
  const [files] = await bucket.getFiles({prefix: RECORDINGS_PREFIX});
  const existing = new Set(files.map((file) => file.name));

  const stalled = findStalledRecordings(
    old.docs.map((doc) => ({
      id: doc.id,
      storagePath: doc.get(F.storagePath),
      createdAt: (doc.get(F.createdAt) as Timestamp).toDate(),
    })),
    existing,
    now,
  );
  await deleteInBatches(stalled.map((id) => db.collection(RECORDINGS).doc(id)));
  return {checked: old.size, deleted: stalled.length};
}
