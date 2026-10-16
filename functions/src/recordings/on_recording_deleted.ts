import {logger} from "firebase-functions";
import {onDocumentDeleted} from "firebase-functions/v2/firestore";

import {bucket, db} from "../lib/admin.js";
import {F, FEEDBACK, RECORDINGS} from "../lib/constants.js";
import {isRecordingFilePath, playbackPathFor, stemPathsOf} from "../lib/recording_files.js";

/**
 * onRecordingDeleted: when `recordings/{recordingId}` is deleted (by its
 * teacher, an admin or cleanupStalledUploads), deletes its audio file, its
 * centred copy `{recordingId}.play.mp3`, the two stems of a two-file
 * recording (still there if they were never joined) and its feedback
 * notes. Clients cannot delete any of them themselves.
 *
 * Safe to run twice (triggers are delivered at least once): a missing file
 * or an empty subcollection is not an error.
 */
export const onRecordingDeleted = onDocumentDeleted(`${RECORDINGS}/{recordingId}`, async (event) => {
  const recordingId = event.params.recordingId;
  const storagePath = event.data?.get(F.storagePath);
  const stems = Object.values(stemPathsOf(event.data?.get(F.stemPaths), recordingId));
  const feedback = db.collection(RECORDINGS).doc(recordingId).collection(FEEDBACK);

  await Promise.all([
    deleteAudio(recordingId, storagePath),
    ...stems.map((path) => bucket.file(path).delete({ignoreNotFound: true})),
    db.recursiveDelete(feedback),
  ]);
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
  // The copy sits next to the original (see onRecordingUploaded); it may
  // not exist (practice, or not analysed yet).
  const studentId = storagePath.split("/")[1];
  await Promise.all([
    bucket.file(storagePath).delete({ignoreNotFound: true}),
    bucket.file(playbackPathFor(studentId, recordingId)).delete({ignoreNotFound: true}),
  ]);
}
