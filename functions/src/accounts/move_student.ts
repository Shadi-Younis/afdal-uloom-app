import {db} from "../lib/admin.js";
import {requireRole} from "../lib/auth_checks.js";
import {updateInBatches} from "../lib/batch.js";
import {callable} from "../lib/callable.js";
import {F, RECORDINGS, USERS} from "../lib/constants.js";
import {failedPrecondition} from "../lib/errors.js";
import {getHalaqa, getUserDoc} from "../lib/lookups.js";
import {asObject, readId} from "../lib/validation.js";

/**
 * moveStudent({studentId, halaqaId}) -> {recordingsUpdated}
 *
 * Admin only. Moves the student and updates halaqaId and teacherId on every
 * recording of the student, so the new teacher sees them and the old one
 * does not. Safe to re-run if it stopped half-way.
 */
export const moveStudent = callable(async (request) => {
  requireRole(request, "admin");
  const data = asObject(request.data);
  const studentId = readId(data, "studentId");
  const halaqaId = readId(data, "halaqaId");

  const student = await getUserDoc(studentId);
  if (student[F.role] !== "student") throw failedPrecondition("User is not a student.");
  const teacherId = (await getHalaqa(halaqaId))[F.teacherId];

  const recordings = await db
    .collection(RECORDINGS)
    .where(F.studentId, "==", studentId)
    .get();

  await updateInBatches([
    {ref: db.collection(USERS).doc(studentId), data: {[F.halaqaId]: halaqaId}},
    ...recordings.docs.map((doc) => ({
      ref: doc.ref,
      data: {[F.halaqaId]: halaqaId, [F.teacherId]: teacherId},
    })),
  ]);

  return {recordingsUpdated: recordings.size};
});
