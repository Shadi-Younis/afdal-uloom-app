import {logger} from "firebase-functions";
import {onDocumentDeleted} from "firebase-functions/v2/firestore";

import {bucket, db} from "../lib/admin.js";
import {F, FEEDBACK, RECORDINGS} from "../lib/constants.js";
import {isRecordingFilePath} from "../lib/recording_files.js";

/**
 * onRecordingDeleted: when `recordings/{recordingId}` is deleted (by its
 * teacher, an admin or cleanupStalledUploads), deletes its audio file and
 * its feedback notes. Clients cannot delete either themselves.
 *
 * Safe to run twice (triggers are delivered at least once): a missing file
 * or an empty subcollection is not an error.
 */
export const onRecordingDeleted = onDocumentDeleted(`${RECORDINGS}/{recordingId}`, async (event) => {
  const recordingId = event.params.recordingId;
  const storagePath = event.data?.get(F.storagePath);
  const feedback = db.collection(RECORDINGS).doc(recordingId).collection(FEEDBACK);

  await Promise.all([deleteAudio(recordingId, storagePath), db.recursiveDelete(feedback)]);
});

async function deleteAudio(recordingId: string, storagePath: unknown): Promise<void> {
  if (!isRecordingFilePath(storagePath, recordingId)) {
    // Never delete a file that is not this recording's own.
    logger.warn("Deleted recording has no valid storagePath; no file deleted.", {
      recordingId,
      storagePath,
    });
    return;
  }
  await bucket.file(storagePath).delete({ignoreNotFound: true});
}
