// Shared by the tests that run onRecordingUploaded on real audio: the
// fixtures built from al-Minshawi's recitations by
// tool/test_audio/build_fixtures.ps1 (outside the repo), and helpers to
// upload them and read what the trigger wrote. Without the fixtures the
// tests that need them are skipped, with a message.
import {existsSync, readFileSync} from "node:fs";
import {join, resolve} from "node:path";

import {Timestamp} from "firebase-admin/firestore";
import {expect} from "vitest";

import {ANALYSIS} from "../src/lib/voice_analysis.js";
import {bucket, db, eventually} from "./helpers.js";

const repo = resolve(__dirname, "..", "..");
export const fixturesDir =
  process.env.TEST_AUDIO_FIXTURES_DIR ?? resolve(repo, "..", "test-audio", "fixtures");
const manifestPath = join(fixturesDir, "manifest.json");

interface Expected {
  start: number;
  end: number;
}

export interface Manifest {
  stereo: {file: string; durationSec: number; sheikhSegments: Expected[]};
  mono: {file: string};
  stems?: {
    student: string;
    sheikh: string;
    bleedDb: number;
    durationSec: number;
    sheikhSegments: Expected[];
    sheikhLong: {file: string; extraSeconds: number};
    sheikhLate: {file: string; lagMs: number};
  };
  swapped?: {file: string; durationSec: number; sheikhSegments: Expected[]};
}

export const haveFixtures = existsSync(manifestPath);
export const manifest: Manifest | null = haveFixtures ? JSON.parse(readFileSync(manifestPath, "utf8")) : null;
/** Built before Task 11 the manifest has no stems: build the fixtures again. */
export const haveStemFixtures = Boolean(manifest?.stems && manifest.swapped);

/** Says once per test file what is skipped and how to build the fixtures. */
export function warnIfMissing(what: string, present: boolean): void {
  if (present) return;
  console.warn(
    `\nSKIPPED ${what}: no (or old) audio fixtures in ${fixturesDir}.\n` +
      "Build them with: powershell -ExecutionPolicy Bypass -File tool/test_audio/build_fixtures.ps1\n",
  );
}

/** How long one analysis may take in the emulator (decode, analyse, encode). */
export const ANALYSIS_TIMEOUT = 60_000;

/** A recording of s1 (h1 / t1) at recordings/s1/{id}.mp3, not reviewed. */
export async function addRecording(
  id: string,
  {
    type = "official",
    createdAt = new Date(),
    extra = {},
  }: {type?: "official" | "practice"; createdAt?: Date; extra?: Record<string, unknown>} = {},
): Promise<string> {
  const storagePath = `recordings/s1/${id}.mp3`;
  await db.doc(`recordings/${id}`).set({
    studentId: "s1",
    halaqaId: "h1",
    teacherId: "t1",
    uploadedBy: type === "official" ? "t1" : "s1",
    type,
    surahNumber: 1,
    ayahFrom: 1,
    ayahTo: 7,
    storagePath,
    durationSec: null,
    recordedAt: Timestamp.fromDate(createdAt),
    createdAt: Timestamp.fromDate(createdAt),
    unreadFeedback: false,
    reviewed: false,
    ...extra,
  });
  return storagePath;
}

export const uploadFixture = (file: string, path: string) =>
  bucket.upload(join(fixturesDir, file), {destination: path, contentType: "audio/mpeg"});

export const recordingData = async (id: string) => (await db.doc(`recordings/${id}`).get()).data() ?? {};

export const analysisOf = async (id: string) =>
  (await recordingData(id)).analysis as Record<string, unknown> | undefined;

export const analysisStatus = async (id: string) => (await analysisOf(id))?.status as string | undefined;

export const waitForStatus = (id: string, statuses: string[], timeoutMs = ANALYSIS_TIMEOUT) =>
  eventually(
    async () => statuses.includes((await analysisStatus(id)) ?? ""),
    `${id} analysed (${statuses.join(" or ")})`,
    timeoutMs,
  );

export async function feedbackOf(id: string) {
  const snapshot = await db.collection(`recordings/${id}/feedback`).get();
  return snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()})) as Array<Record<string, unknown>>;
}

export const voiceMarkers = async (id: string) =>
  (await feedbackOf(id))
    .filter((note) => note.kind === "voice")
    .sort((a, b) => (a.atSecond as number) - (b.atSecond as number));

/**
 * One marker per [expected] place of the sheikh, within 0.5 s: a marker
 * starts ANALYSIS.leadInSeconds early and is floored to the second, and
 * ends rounded to the second.
 */
export function expectMarkersAt(markers: Array<Record<string, unknown>>, expected: Expected[]): void {
  expect(markers).toHaveLength(expected.length);
  expected.forEach((place, i) => {
    const marker = markers[i];
    const start = place.start - ANALYSIS.leadInSeconds;
    expect(marker.atSecond).toBeGreaterThanOrEqual(Math.floor(start - 0.5));
    expect(marker.atSecond).toBeLessThanOrEqual(Math.floor(start + 0.5));
    expect(marker.endSecond).toBeGreaterThanOrEqual(Math.round(place.end - 0.5));
    expect(marker.endSecond).toBeLessThanOrEqual(Math.round(place.end + 0.5));
    expect(marker).toMatchObject({teacherId: "t1", note: "", rating: null});
    expect(marker.createdAt).toBeInstanceOf(Timestamp);
  });
}

export const fileExists = async (path: string) => (await bucket.file(path).exists())[0];

/** The names of every object of recording [id] in s1's folder. */
export async function filesOf(id: string): Promise<string[]> {
  const [files] = await bucket.getFiles({prefix: `recordings/s1/${id}.`});
  return files.map((file) => file.name).sort();
}
