import {CallableRequest, HttpsError} from "firebase-functions/v2/https";

import {ROLES, Role} from "./constants.js";
import {permissionDenied} from "./errors.js";

export interface Caller {
  uid: string;
  role: Role;
}

/**
 * The caller, if signed in with one of [allowed] roles. The role comes only
 * from the `role` custom claim.
 *
 * Throws `unauthenticated` when signed out, `permission-denied` otherwise.
 */
export function requireRole(request: CallableRequest, ...allowed: Role[]): Caller {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  const role = request.auth.token.role;
  if (!ROLES.includes(role) || !allowed.includes(role)) {
    throw permissionDenied(`Role ${String(role)} may not call this function.`);
  }
  return {uid: request.auth.uid, role};
}
