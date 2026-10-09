// Pure helpers about recording audio files: no Firebase calls, so they are
// tested without emulators.
import {RECORDINGS, STALLED_UPLOAD_AGE_MS} from "./constants.js";

/** Prefix of every recording file in the bucket. */
export const RECORDINGS_PREFIX = `${RECORDINGS}/`;

/**
 * Whether [storagePath] is the file of recording [recordingId]:
 * `recordings/{studentId}/{recordingId}.{ext}`. The cleanup functions only
 * delete such paths, so a malformed document can never point them at
 * another file.
 */
export function isRecordingFilePath(storagePath: unknown, recordingId: string): storagePath is string {
  if (typeof storagePath !== "string") return false;
  const parts = storagePath.split("/");
  if (parts.length !== 3 || parts[0] !== RECORDINGS || parts[1] === "") return false;
  const dot = parts[2].lastIndexOf(".");
  if (dot <= 0) return false;
  return parts[2].slice(0, dot) === recordingId && /^[a-z0-9]+$/.test(parts[2].slice(dot + 1));
}

export interface RecordingFileInfo {
  id: string;
  storagePath: unknown;
  createdAt: Date;
}

/**
 * The ids of the stalled uploads among [recordings]: created at least
 * [maxAgeMs] before [now], with a valid storagePath whose file is not in
 * [existingFiles]. A document without a valid storagePath is left alone.
 */
export function findStalledRecordings(
  recordings: readonly RecordingFileInfo[],
  existingFiles: ReadonlySet<string>,
  now: Date,
  maxAgeMs = STALLED_UPLOAD_AGE_MS,
): string[] {
  const cutoff = now.getTime() - maxAgeMs;
  return recordings
    .filter((r) => r.createdAt.getTime() <= cutoff)
    .filter((r) => isRecordingFilePath(r.storagePath, r.id) && !existingFiles.has(r.storagePath))
    .map((r) => r.id);
}
