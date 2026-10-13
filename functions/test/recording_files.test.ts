// The pure helpers behind onRecordingDeleted, onRecordingUploaded and
// cleanupStalledUploads, and the generated surah table.
import {describe, expect, test} from "vitest";

import {
  findStalledRecordings,
  isRecordingFilePath,
  isStemPath,
  parseRecordingUpload,
  playbackPathFor,
  stemPathsOf,
} from "../src/lib/recording_files.js";
import {AYAH_COUNTS, isValidAyahRange} from "../src/lib/surahs.js";

describe("parseRecordingUpload and playbackPathFor", () => {
  test("an uploaded recording names its student and recording", () => {
    expect(parseRecordingUpload("recordings/s1/r1.mp3")).toEqual({studentId: "s1", recordingId: "r1"});
    expect(parseRecordingUpload("recordings/s1/r1.wav")).toEqual({studentId: "s1", recordingId: "r1"});
    expect(parseRecordingUpload("recordings/s1/r1.webm")).toEqual({studentId: "s1", recordingId: "r1"});
  });

  test("the playback copy and anything else are ignored", () => {
    expect(parseRecordingUpload("recordings/s1/r1.play.mp3")).toBeNull();
    expect(parseRecordingUpload("recordings/s1/r1.exe")).toBeNull();
    expect(parseRecordingUpload("recordings/s1/r1.MP3")).toBeNull();
    expect(parseRecordingUpload("recordings/s1/r1")).toBeNull();
    expect(parseRecordingUpload("recordings/s1/sub/r1.mp3")).toBeNull();
    expect(parseRecordingUpload("recordings//r1.mp3")).toBeNull();
    expect(parseRecordingUpload("other/s1/r1.mp3")).toBeNull();
    expect(parseRecordingUpload(undefined)).toBeNull();
  });

  test("a stem of a two-file recording names its role", () => {
    expect(parseRecordingUpload("recordings/s1/r1.student.wav")).toEqual({
      studentId: "s1",
      recordingId: "r1",
      stem: "student",
    });
    expect(parseRecordingUpload("recordings/s1/r1.sheikh.mp3")).toEqual({
      studentId: "s1",
      recordingId: "r1",
      stem: "sheikh",
    });
    expect(parseRecordingUpload("recordings/s1/r1.teacher.mp3")).toBeNull();
    expect(parseRecordingUpload("recordings/s1/r1.student.exe")).toBeNull();
    expect(parseRecordingUpload("recordings/s1/r1.student.sheikh.mp3")).toBeNull();
    expect(parseRecordingUpload("recordings/s1/r1.Student.mp3")).toBeNull();
  });

  test("the playback copy sits next to the original", () => {
    expect(playbackPathFor("s1", "r1")).toBe("recordings/s1/r1.play.mp3");
  });
});

describe("isRecordingFilePath", () => {
  test("accepts recordings/{studentId}/{recordingId}.{ext}", () => {
    expect(isRecordingFilePath("recordings/s1/r1.mp3", "r1")).toBe(true);
    expect(isRecordingFilePath("recordings/s1/r1.webm", "r1")).toBe(true);
  });

  test("rejects another recording's file, other folders and malformed values", () => {
    expect(isRecordingFilePath("recordings/s1/r2.mp3", "r1")).toBe(false);
    expect(isRecordingFilePath("recordings/s1/r1", "r1")).toBe(false);
    expect(isRecordingFilePath("recordings/s1/.mp3", "")).toBe(false);
    expect(isRecordingFilePath("recordings//r1.mp3", "r1")).toBe(false);
    expect(isRecordingFilePath("other/s1/r1.mp3", "r1")).toBe(false);
    expect(isRecordingFilePath("recordings/s1/x/r1.mp3", "r1")).toBe(false);
    expect(isRecordingFilePath("recordings/s1/r1.MP3/..", "r1")).toBe(false);
    expect(isRecordingFilePath(null, "r1")).toBe(false);
    expect(isRecordingFilePath(42, "r1")).toBe(false);
  });
});

describe("isStemPath and stemPathsOf", () => {
  test("a stem path of this recording and role only", () => {
    expect(isStemPath("recordings/s1/r1.student.mp3", "r1", "student")).toBe(true);
    expect(isStemPath("recordings/s1/r1.sheikh.wav", "r1", "sheikh")).toBe(true);
    expect(isStemPath("recordings/s1/r1.sheikh.wav", "r1", "student")).toBe(false);
    expect(isStemPath("recordings/s1/r2.student.mp3", "r1", "student")).toBe(false);
    expect(isStemPath("recordings/s1/r1.mp3", "r1", "student")).toBe(false);
    expect(isStemPath("recordings/s1/r1.play.mp3", "r1", "student")).toBe(false);
    expect(isStemPath("other/s1/r1.student.mp3", "r1", "student")).toBe(false);
    expect(isStemPath(7, "r1", "student")).toBe(false);
  });

  test("keeps the valid stems of a document's stemPaths", () => {
    expect(
      stemPathsOf({student: "recordings/s1/r1.student.mp3", sheikh: "recordings/s1/r1.sheikh.wav"}, "r1"),
    ).toEqual({student: "recordings/s1/r1.student.mp3", sheikh: "recordings/s1/r1.sheikh.wav"});
    expect(stemPathsOf({student: "recordings/s1/r1.student.mp3", sheikh: "recordings/s2/x.mp3"}, "r1")).toEqual({
      student: "recordings/s1/r1.student.mp3",
    });
    expect(stemPathsOf(undefined, "r1")).toEqual({});
    expect(stemPathsOf("recordings/s1/r1.student.mp3", "r1")).toEqual({});
  });
});

describe("findStalledRecordings", () => {
  const now = new Date("2026-10-09T00:00:00Z");
  const hoursAgo = (h: number) => new Date(now.getTime() - h * 3600_000);
  const rec = (id: string, ageHours: number, storagePath: unknown = `recordings/s1/${id}.mp3`) => ({
    id,
    storagePath,
    createdAt: hoursAgo(ageHours),
  });

  test("only old recordings whose file is missing", () => {
    const recordings = [
      rec("old-missing", 25),
      rec("old-present", 25),
      rec("fresh-missing", 23),
      rec("exactly-24h", 24),
    ];
    const existing = new Set(["recordings/s1/old-present.mp3"]);
    expect(findStalledRecordings(recordings, existing, now)).toEqual(["old-missing", "exactly-24h"]);
  });

  test("a document without a valid storagePath is left alone", () => {
    const recordings = [rec("a", 48, null), rec("b", 48, "recordings/s1/other.mp3")];
    expect(findStalledRecordings(recordings, new Set(), now)).toEqual([]);
  });

  test("nothing to do", () => {
    expect(findStalledRecordings([], new Set(), now)).toEqual([]);
  });
});

describe("surahs.ts (generated)", () => {
  test("114 surahs, 6236 ayat", () => {
    expect(AYAH_COUNTS).toHaveLength(114);
    expect(AYAH_COUNTS.reduce((sum, n) => sum + n, 0)).toBe(6236);
  });

  test("isValidAyahRange", () => {
    expect(isValidAyahRange(2, 1, 286)).toBe(true);
    expect(isValidAyahRange(2, 1, 287)).toBe(false);
    expect(isValidAyahRange(115, 1, 1)).toBe(false);
    expect(isValidAyahRange(1, 3, 2)).toBe(false);
    expect(isValidAyahRange(1, 1.5, 2)).toBe(false);
  });
});
