// Shared by every function. Values that the app also uses are mirrored in
// lib/core/constants/ on the Dart side; change both together.

/** Every function runs next to Firestore and Storage (Tel Aviv). App: FirebaseConstants.functionsRegion. */
export const REGION = "me-west1";

/** Usernames become `${username}@${EMAIL_DOMAIN}`. App: FirebaseConstants.emailDomain. */
export const EMAIL_DOMAIN = "afdal-uloom.app";

export const ROLES = ["admin", "teacher", "student"] as const;
export type Role = (typeof ROLES)[number];

export const USERNAME_PATTERN = /^[a-z0-9._-]+$/;
export const USERNAME_LENGTH = {min: 3, max: 20};
export const PASSWORD_LENGTH = {min: 6, max: 64};
export const FULL_NAME_LENGTH = {min: 2, max: 60};
export const STUDENT_CODE_PATTERN = /^S\d{3,5}$/;
/** Document ids sent by the app: Firestore allows up to 1500 bytes, real ones are ~20-28 chars. */
export const ID_LENGTH = {min: 1, max: 128};

/** Firestore's limit of writes per batch. */
export const BATCH_LIMIT = 500;

// Firestore paths and fields (docs/PROJECT_PLAN.md section 3). App: FirestorePaths / Fields.
export const USERS = "users";
export const HALAQAT = "halaqat";
export const RECORDINGS = "recordings";
export const F = {
  username: "username",
  fullName: "fullName",
  role: "role",
  studentCode: "studentCode",
  halaqaId: "halaqaId",
  fcmTokens: "fcmTokens",
  createdAt: "createdAt",
  disabled: "disabled",
  teacherId: "teacherId",
  studentId: "studentId",
} as const;

export function emailFor(username: string): string {
  return `${username}@${EMAIL_DOMAIN}`;
}
