// Shared by every function. Values that the app also uses are mirrored in
// lib/core/constants/ on the Dart side; change both together.

/** Every function runs next to Firestore and Storage (Tel Aviv). App: FirebaseConstants.functionsRegion. */
export const REGION = "me-west1";

/** Usernames become `${username}@${EMAIL_DOMAIN}`. App: FirebaseConstants.emailDomain. */
export const EMAIL_DOMAIN = "afdal-uloom.app";

/**
 * The default bucket, as in lib/firebase_options.dart (storageBucket). Named
 * explicitly: the emulators would otherwise guess `<project>.appspot.com`,
 * another bucket than the one the app uploads to. App: FirebaseConstants.storageBucket.
 */
export const STORAGE_BUCKET = "afdal-al-uloom.firebasestorage.app";

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
/** Subcollection of a recording. */
export const FEEDBACK = "feedback";
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
  /** halaqat: a copy of the teacher's fullName, for the students. */
  teacherName: "teacherName",
  studentId: "studentId",
  storagePath: "storagePath",
  type: "type",
  durationSec: "durationSec",
  unreadFeedback: "unreadFeedback",
  analysis: "analysis",
  playbackPath: "playbackPath",
  /** recordings: "stereo" (missing = stereo) or "stems". */
  source: "source",
  /** recordings of source "stems": {student, sheikh} Storage paths. */
  stemPaths: "stemPaths",
  // recordings/{id}/feedback
  kind: "kind",
  note: "note",
  atSecond: "atSecond",
  endSecond: "endSecond",
} as const;

/** recordings.type of a studio recording; only these are analysed. */
export const OFFICIAL = "official";

/**
 * recordings.source: one stereo file (student left, sheikh right), or two
 * stems (one per microphone) that the server joins into that stereo file.
 * App: RecordingSource.
 */
export const SOURCE = {
  stereo: "stereo",
  stems: "stems",
} as const;

/** feedback.kind of a marker the server found in the sheikh's channel. */
export const VOICE = "voice";

/** analysis.status values (docs/PROJECT_PLAN.md section 3). */
export const ANALYSIS_STATUS = {
  /** Two stems: both arrived, the server joins them into the stereo file. */
  merging: "merging",
  pending: "pending",
  done: "done",
  mono: "mono",
  failed: "failed",
} as const;

/**
 * The audio extensions a recording's storagePath may have, as in
 * firestore.rules. App: AudioFormats.contentTypes.
 */
export const AUDIO_EXTENSIONS = ["mp3", "m4a", "aac", "wav", "ogg", "webm"] as const;

/**
 * onRecordingUploaded: enough memory and time for a long studio session
 * (decode, analyse, encode the playback copy).
 */
export const ANALYSIS_MEMORY = "1GiB";
export const ANALYSIS_TIMEOUT_SECONDS = 300;
export const ANALYSIS_MAX_INSTANCES = 10;

/** A recording whose audio file is still missing this long after createdAt is a failed upload. */
export const STALLED_UPLOAD_AGE_MS = 24 * 60 * 60 * 1000;

/** cleanupStalledUploads runs daily at 00:00 UTC, the middle of the school's night. */
export const CLEANUP_SCHEDULE = "0 0 * * *";
export const CLEANUP_TIME_ZONE = "Etc/UTC";

export function emailFor(username: string): string {
  return `${username}@${EMAIL_DOMAIN}`;
}
