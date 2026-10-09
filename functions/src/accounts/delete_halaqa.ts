import {db} from "../lib/admin.js";
import {requireRole} from "../lib/auth_checks.js";
import {callable} from "../lib/callable.js";
import {F, HALAQAT, RECORDINGS, USERS} from "../lib/constants.js";
import {failedPrecondition, notFound} from "../lib/errors.js";
import {asObject, readId} from "../lib/validation.js";

/**
 * deleteHalaqa({halaqaId}) -> null
 *
 * Admin only. Deletes an empty halaqa. Refused with `failed-precondition`
 * while any student, active or disabled, belongs to it (reason
 * `hasStudents`: move them first), or while a recording still points to it
 * (reason `hasRecordings`; recordings move with their student, so this
 * only guards against inconsistent data). The checks and the delete run
 * in one transaction.
 */
export const deleteHalaqa = callable(async (request) => {
  requireRole(request, "admin");
  const halaqaId = readId(asObject(request.data), "halaqaId");
  const halaqaRef = db.collection(HALAQAT).doc(halaqaId);

  await db.runTransaction(async (transaction) => {
    const halaqa = await transaction.get(halaqaRef);
    if (!halaqa.exists) throw notFound("Halaqa not found.");
    const students = await transaction.get(
      db.collection(USERS).where(F.halaqaId, "==", halaqaId).limit(1),
    );
    if (!students.empty) {
      throw failedPrecondition("The halaqa still has students.", "hasStudents");
    }
    const recordings = await transaction.get(
      db.collection(RECORDINGS).where(F.halaqaId, "==", halaqaId).limit(1),
    );
    if (!recordings.empty) {
      throw failedPrecondition("Recordings still belong to the halaqa.", "hasRecordings");
    }
    transaction.delete(halaqaRef);
  });
  return null;
});
