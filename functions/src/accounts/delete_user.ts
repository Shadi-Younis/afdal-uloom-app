import {auth, bucket, db} from "../lib/admin.js";
import {requireRole} from "../lib/auth_checks.js";
import {deleteInBatches} from "../lib/batch.js";
import {callable} from "../lib/callable.js";
import {F, HALAQAT, RECORDINGS, USERS} from "../lib/constants.js";
import {adminErrorCode, failedPrecondition, notFound, permissionDenied} from "../lib/errors.js";
import {RECORDINGS_PREFIX} from "../lib/recording_files.js";
import {asObject, readId} from "../lib/validation.js";

/**
 * deleteUser({uid}) -> {recordingsDeleted}
 *
 * Admin only. Deletes a teacher or a student for good; admins (including
 * the caller) can never be deleted.
 *
 * - Teacher: refused with `failed-precondition` (reason `ownsHalaqat`)
 *   while they teach a halaqa. Their feedback notes stay on the
 *   recordings; the app shows the author as a former teacher.
 * - Student: every recording is deleted (onRecordingDeleted then removes
 *   its file and feedback), then the users doc, then the Auth user.
 *
 * Safe to re-run if it stopped half-way: with the users doc already gone,
 * the role is read from the Auth user's claim and the rest is finished.
 */
export const deleteUser = callable(async (request) => {
  const caller = requireRole(request, "admin");
  const uid = readId(asObject(request.data), "uid");
  if (uid === caller.uid) throw permissionDenied("Admins cannot delete themselves.");

  const userRef = db.collection(USERS).doc(uid);
  const role = await roleOf(uid);
  if (role === "admin") throw permissionDenied("Admin accounts cannot be deleted.");

  let recordingsDeleted = 0;
  if (role === "teacher") {
    // In one transaction, so a halaqa given to them meanwhile is not orphaned.
    await db.runTransaction(async (transaction) => {
      const halaqat = await transaction.get(
        db.collection(HALAQAT).where(F.teacherId, "==", uid).limit(1),
      );
      if (!halaqat.empty) {
        throw failedPrecondition("The teacher still teaches a halaqa.", "ownsHalaqat");
      }
      transaction.delete(userRef);
    });
  } else {
    const recordings = await db.collection(RECORDINGS).where(F.studentId, "==", uid).get();
    await deleteInBatches(recordings.docs.map((doc) => doc.ref));
    recordingsDeleted = recordings.size;
    // The triggers delete each recording's file; this also removes any file
    // left without a document (e.g. by an interrupted upload).
    await bucket.deleteFiles({prefix: `${RECORDINGS_PREFIX}${uid}/`});
    await userRef.delete();
  }

  await auth.deleteUser(uid).catch((error) => {
    if (adminErrorCode(error) !== "auth/user-not-found") throw error;
  });
  return {recordingsDeleted};
});

/**
 * The role of [uid]: from the users doc, or from the Auth claim when a
 * previous run already deleted the doc. Admin wins if either says so.
 * Throws `not-found` when neither exists.
 */
async function roleOf(uid: string): Promise<"admin" | "teacher" | "student"> {
  const doc = await db.collection(USERS).doc(uid).get();
  const claim = await auth.getUser(uid).then(
    (user) => user.customClaims?.role as unknown,
    (error) => {
      if (adminErrorCode(error) === "auth/user-not-found") return undefined;
      throw error;
    },
  );
  const docRole = doc.exists ? doc.get(F.role) : undefined;
  if (docRole === "admin" || claim === "admin") return "admin";
  const role = docRole ?? claim;
  if (role === "teacher" || role === "student") return role;
  if (!doc.exists && claim === undefined) throw notFound("User not found.");
  // A doc or claim without a valid role: nothing this function should guess at.
  throw failedPrecondition("User has no valid role.");
}
