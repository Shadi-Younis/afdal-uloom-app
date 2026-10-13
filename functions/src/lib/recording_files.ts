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

/** The two stems of a two-file recording: one per microphone. */
export const STEM_ROLES = ["student", "sheikh"] as const;
export type StemRole = (typeof STEM_ROLES)[number];

export interface RecordingUpload {
  studentId: string;
  recordingId: string;
  /** Set for a stem of a two-file recording (`{recordingId}.{stem}.{ext}`). */
  stem?: StemRole;
}

/**
 * The recording an uploaded object belongs to, when [name] is
 * `recordings/{studentId}/{recordingId}.{ext}`, or a stem
 * `recordings/{studentId}/{recordingId}.student.{ext}` /
 * `.sheikh.{ext}`, with an accepted audio extension; null for anything
 * else, the `.play.mp3` copies included (the server writes those itself).
 */
export function parseRecordingUpload(name: string | undefined): RecordingUpload | null {
  if (!name || name.endsWith(PLAYBACK_SUFFIX)) return null;
  const parts = name.split("/");
  if (parts.length !== 3 || parts[0] !== RECORDINGS || parts[1] === "") return null;
  const match = /^([^.]+)(?:\.(student|sheikh))?\.([a-z0-9]+)$/.exec(parts[2]);
  if (!match || !(AUDIO_EXTENSIONS as readonly string[]).includes(match[3])) return null;
  const upload: RecordingUpload = {studentId: parts[1], recordingId: match[1]};
  if (match[2]) upload.stem = match[2] as StemRole;
  return upload;
}

/**
 * Whether [path] is the [stem] of recording [recordingId]:
 * `recordings/{studentId}/{recordingId}.{stem}.{ext}` with an accepted
 * audio extension. Like isRecordingFilePath, it keeps the server from ever
 * reading or deleting a file a malformed document points at.
 */
export function isStemPath(path: unknown, recordingId: string, stem: StemRole): path is string {
  if (typeof path !== "string") return false;
  const upload = parseRecordingUpload(path);
  return upload !== null && upload.recordingId === recordingId && upload.stem === stem;
}

/** The valid stem paths in a document's [stemPaths] value (none for a stereo recording). */
export function stemPathsOf(stemPaths: unknown, recordingId: string): Partial<Record<StemRole, string>> {
  const result: Partial<Record<StemRole, string>> = {};
  if (typeof stemPaths !== "object" || stemPaths === null) return result;
  for (const stem of STEM_ROLES) {
    const path = (stemPaths as Record<string, unknown>)[stem];
    if (isStemPath(path, recordingId, stem)) result[stem] = path;
  }
  return result;
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
