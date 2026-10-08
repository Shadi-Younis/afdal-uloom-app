import {logger} from "firebase-functions";
import {HttpsError} from "firebase-functions/v2/https";

// Messages are English and meant for logs and developers; the app shows
// its own Arabic text per error code.

export const invalidArgument = (message: string) =>
  new HttpsError("invalid-argument", message);

export const permissionDenied = (message = "You are not allowed to do this.") =>
  new HttpsError("permission-denied", message);

export const notFound = (message: string) => new HttpsError("not-found", message);

export const alreadyExists = (message: string, field: string) =>
  new HttpsError("already-exists", message, {field});

export const failedPrecondition = (message: string) =>
  new HttpsError("failed-precondition", message);

/** The `code` of a firebase-admin error (e.g. `auth/user-not-found`), if any. */
export function adminErrorCode(error: unknown): string | undefined {
  const code = (error as {code?: unknown} | null)?.code;
  return typeof code === "string" ? code : undefined;
}

/**
 * Rethrows [error] as an HttpsError: an HttpsError passes through, a known
 * Auth error gets its matching code, anything else is logged and becomes
 * `internal` without details.
 */
export function toHttpsError(error: unknown): HttpsError {
  if (error instanceof HttpsError) return error;
  switch (adminErrorCode(error)) {
  case "auth/user-not-found":
    return notFound("User not found.");
  case "auth/email-already-exists":
    return alreadyExists("Username already exists.", "username");
  case "auth/invalid-password":
    return invalidArgument("Invalid password.");
  }
  logger.error("Unexpected error", error);
  return new HttpsError("internal", "Internal error.");
}
