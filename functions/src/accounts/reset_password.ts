import {auth} from "../lib/admin.js";
import {requireRole} from "../lib/auth_checks.js";
import {callable} from "../lib/callable.js";
import {F} from "../lib/constants.js";
import {permissionDenied} from "../lib/errors.js";
import {getUserDoc, teacherOwnsStudent} from "../lib/lookups.js";
import {asObject, readId, readPassword} from "../lib/validation.js";

/**
 * resetPassword({uid, newPassword}) -> null
 *
 * Admin: any non-admin user, and themselves. Teacher: only a student in a
 * halaqa they own. Revokes the user's refresh tokens so every old session
 * has to sign in again.
 */
export const resetPassword = callable(async (request) => {
  const caller = requireRole(request, "admin", "teacher");
  const data = asObject(request.data);
  const uid = readId(data, "uid");
  const newPassword = readPassword(data, "newPassword");

  if (caller.role === "admin") {
    const target = await getUserDoc(uid);
    if (target[F.role] === "admin" && uid !== caller.uid) {
      throw permissionDenied("Admins cannot reset another admin's password.");
    }
  } else if (!(await teacherOwnsStudent(caller.uid, uid))) {
    // Same answer whether the user is missing or not theirs: a teacher
    // learns nothing about users outside their halaqat.
    throw permissionDenied("Teachers can only reset their own students.");
  }

  await auth.updateUser(uid, {password: newPassword});
  await auth.revokeRefreshTokens(uid);
  return null;
});
