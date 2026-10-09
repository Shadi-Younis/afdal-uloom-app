// The pure helpers behind onRecordingDeleted and cleanupStalledUploads, and
// the generated surah table.
import {describe, expect, test} from "vitest";

import {findStalledRecordings, isRecordingFilePath} from "../src/lib/recording_files.js";
import {AYAH_COUNTS, isValidAyahRange} from "../src/lib/surahs.js";

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
