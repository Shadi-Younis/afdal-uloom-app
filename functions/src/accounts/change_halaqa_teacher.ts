import {db} from "../lib/admin.js";
import {requireRole} from "../lib/auth_checks.js";
import {updateInBatches} from "../lib/batch.js";
import {callable} from "../lib/callable.js";
import {F, HALAQAT, RECORDINGS} from "../lib/constants.js";
import {failedPrecondition} from "../lib/errors.js";
import {getHalaqa, getUserDoc} from "../lib/lookups.js";
import {asObject, readId} from "../lib/validation.js";

/**
 * changeHalaqaTeacher({halaqaId, teacherId}) -> {recordingsUpdated}
 *
 * Admin only. Gives the halaqa to another teacher and updates teacherId on
 * every recording of that halaqa (it is copied there for queries and
 * security rules). Safe to re-run if it stopped half-way.
 */
export const changeHalaqaTeacher = callable(async (request) => {
  requireRole(request, "admin");
  const data = asObject(request.data);
  const halaqaId = readId(data, "halaqaId");
  const teacherId = readId(data, "teacherId");

  await getHalaqa(halaqaId);
  const teacher = await getUserDoc(teacherId);
  if (teacher[F.role] !== "teacher") throw failedPrecondition("User is not a teacher.");

  const recordings = await db
    .collection(RECORDINGS)
    .where(F.halaqaId, "==", halaqaId)
    .get();

  await updateInBatches([
    {ref: db.collection(HALAQAT).doc(halaqaId), data: {[F.teacherId]: teacherId}},
    ...recordings.docs.map((doc) => ({ref: doc.ref, data: {[F.teacherId]: teacherId}})),
  ]);

  return {recordingsUpdated: recordings.size};
});
