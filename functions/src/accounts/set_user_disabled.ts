import {auth} from "../lib/admin.js";
import {requireRole} from "../lib/auth_checks.js";
import {callable} from "../lib/callable.js";
import {permissionDenied} from "../lib/errors.js";
import {asObject, readBoolean, readId} from "../lib/validation.js";

/**
 * setUserDisabled({uid, disabled}) -> null
 *
 * Admin only, never on themselves (the school must not lock out its last
 * admin by accident). Disables or enables the Auth account; no data is
 * deleted. Disabling also revokes refresh tokens, so open sessions end
 * within the hour instead of lasting until the next sign-in.
 */
export const setUserDisabled = callable(async (request) => {
  const caller = requireRole(request, "admin");
  const data = asObject(request.data);
  const uid = readId(data, "uid");
  const disabled = readBoolean(data, "disabled");

  if (uid === caller.uid) throw permissionDenied("Admins cannot disable themselves.");

  await auth.updateUser(uid, {disabled});
  if (disabled) await auth.revokeRefreshTokens(uid);
  return null;
});
