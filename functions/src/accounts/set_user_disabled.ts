import {auth, db} from "../lib/admin.js";
import {requireRole} from "../lib/auth_checks.js";
import {callable} from "../lib/callable.js";
import {F, USERS} from "../lib/constants.js";
import {permissionDenied} from "../lib/errors.js";
import {getUserDoc} from "../lib/lookups.js";
import {asObject, readBoolean, readId} from "../lib/validation.js";

/**
 * setUserDisabled({uid, disabled}) -> null
 *
 * Admin only, never on themselves (the school must not lock out its last
 * admin by accident). Disables or enables the Auth account and copies the
 * state to `users/{uid}.disabled`, which the app shows; no data is deleted.
 * Disabling also revokes refresh tokens, so open sessions end within the
 * hour instead of lasting until the next sign-in. Safe to re-run if it
 * stopped half-way.
 */
export const setUserDisabled = callable(async (request) => {
  const caller = requireRole(request, "admin");
  const data = asObject(request.data);
  const uid = readId(data, "uid");
  const disabled = readBoolean(data, "disabled");

  if (uid === caller.uid) throw permissionDenied("Admins cannot disable themselves.");
  // Checked first: an Auth user without a users doc would be left half-done.
  await getUserDoc(uid);

  // Auth first: it is what blocks signing in, so a failure after it never
  // shows an account as disabled that can still sign in.
  await auth.updateUser(uid, {disabled});
  if (disabled) await auth.revokeRefreshTokens(uid);
  await db.collection(USERS).doc(uid).update({[F.disabled]: disabled});
  return null;
});
