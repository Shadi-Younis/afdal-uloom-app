// Pure helpers about recording audio files: no Firebase calls, so they are
// tested without emulators.
import {AUDIO_EXTENSIONS, RECORDINGS, STALLED_UPLOAD_AGE_MS} from "./constants.js";

/** Prefix of every recording file in the bucket. */
export const RECORDINGS_PREFIX = `${RECORDINGS}/`;

/** What follows the recording id in the name of its centred copy. App: StoragePaths.playbackSuffix. */
export const PLAYBACK_SUFFIX = ".play.mp3";

/** `recordings/{studentId}/{recordingId}.play.mp3`. App: StoragePaths.playback. */
export function playbackPathFor(studentId: string, recordingId: string): string {
  return `${RECORDINGS}/${studentId}/${recordingId}${PLAYBACK_SUFFIX}`;
}

export interface RecordingUpload {
  studentId: string;
  recordingId: string;
}

/**
 * The recording an uploaded object belongs to, when [name] is
 * `recordings/{studentId}/{recordingId}.{ext}` with an accepted audio
 * extension; null for anything else, the `.play.mp3` copies included (the
 * server writes those itself).
 */
export function parseRecordingUpload(name: string | undefined): RecordingUpload | null {
  if (!name || name.endsWith(PLAYBACK_SUFFIX)) return null;
  const parts = name.split("/");
  if (parts.length !== 3 || parts[0] !== RECORDINGS || parts[1] === "") return null;
  const match = /^([^.]+)\.([a-z0-9]+)$/.exec(parts[2]);
  if (!match || !(AUDIO_EXTENSIONS as readonly string[]).includes(match[2])) return null;
  return {studentId: parts[1], recordingId: match[1]};
}

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
