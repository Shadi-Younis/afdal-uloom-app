// The recitations every seeded recording plays: al-Minshawi (murattal),
// listed in tool/seed/test_audio.json and downloaded OUTSIDE the repo by
// tool/seed/download_test_audio.ps1. Never committed, never uploaded to the
// real project.

import { existsSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { mp3DurationSeconds } from "./mp3.js";

export interface Clip {
  id: string;
  file: string;
  url: string;
  surahNumber: number;
  ayahFrom: number;
  ayahTo: number;
}

/**
 * The studio recording of the seed: al-Fatiha on the LEFT (the student)
 * and al-Ikhlas on the RIGHT (the sheikh) in two gaps, as Studio One
 * exports the left / right template. Built from the recitations by
 * tool/test_audio/build_fixtures.mjs (outside the repo), so the emulator's
 * onRecordingUploaded finds two voice markers in it.
 */
export const studioClip: Clip = {
  id: "studio-stereo",
  file: "stereo_two_corrections.mp3",
  url: "tool/test_audio/build_fixtures.mjs",
  surahNumber: 1,
  ayahFrom: 1,
  ayahTo: 7,
};

/**
 * The same session sent as two files (Task 11): the student's and the
 * sheikh's microphones as two mono stems, each voice at -15 dB in the other
 * one. The emulator's onRecordingUploaded joins them into the stereo file
 * and finds the sheikh twice.
 */
export const studioStemsClip: Clip = {
  id: "studio-stems",
  file: "stems_student.mp3 + stems_sheikh.mp3",
  url: "tool/test_audio/build_fixtures.mjs",
  surahNumber: 1,
  ayahFrom: 1,
  ayahTo: 7,
};

/** The stems joined the wrong way round (the sheikh LEFT): the server swaps them back. */
export const studioSwappedClip: Clip = {
  id: "studio-swapped",
  file: "stereo_swapped.mp3",
  url: "tool/test_audio/build_fixtures.mjs",
  surahNumber: 1,
  ayahFrom: 1,
  ayahTo: 7,
};

export interface ClipAudio {
  mp3: Buffer;
  durationSec: number;
}

const seedDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repoDir = resolve(seedDir, "..", "..");

export const clips: Clip[] = JSON.parse(
  readFileSync(join(seedDir, "test_audio.json"), "utf8"),
).clips;

/** Where the downloaded files are: SEED_AUDIO_DIR, or ..\test-audio\minshawi next to the repo. */
export const audioDir = process.env.SEED_AUDIO_DIR ?? resolve(repoDir, "..", "test-audio", "minshawi");

/** The clips whose file is not in [audioDir]. */
export function missingClips(): Clip[] {
  return clips.filter((clip) => !existsSync(join(audioDir, clip.file)));
}

/** The studio fixtures (tool/test_audio), built first when one is missing. */
async function studioFixture(file: string): Promise<Buffer> {
  const fixtures = await import("../../test_audio/build_fixtures.mjs");
  const needed = [
    fixtures.STEREO_FILE,
    fixtures.SWAPPED_FILE,
    fixtures.STEMS_STUDENT_FILE,
    fixtures.STEMS_SHEIKH_FILE,
  ];
  if (needed.some((name) => !existsSync(join(fixtures.fixturesDir, name)))) fixtures.buildFixtures();
  return readFileSync(join(fixtures.fixturesDir, file));
}

const withDuration = (mp3: Buffer): ClipAudio => ({ mp3, durationSec: Math.round(mp3DurationSeconds(mp3)) });

/** Every clip's file and its duration in whole seconds, by clip id; the stereo studio clips too. */
export async function loadClipAudio(): Promise<Map<string, ClipAudio>> {
  const audio = new Map(
    clips.map((clip): [string, ClipAudio] => [clip.id, withDuration(readFileSync(join(audioDir, clip.file)))]),
  );
  for (const clip of [studioClip, studioSwappedClip]) {
    audio.set(clip.id, withDuration(await studioFixture(clip.file)));
  }
  return audio;
}

export interface StemsAudio {
  student: Buffer;
  sheikh: Buffer;
  durationSec: number;
}

/** The two files of [studioStemsClip]. */
export async function loadStemsAudio(): Promise<StemsAudio> {
  const { STEMS_STUDENT_FILE, STEMS_SHEIKH_FILE } = await import("../../test_audio/build_fixtures.mjs");
  const student = await studioFixture(STEMS_STUDENT_FILE);
  const sheikh = await studioFixture(STEMS_SHEIKH_FILE);
  return { student, sheikh, durationSec: withDuration(student).durationSec };
}

export interface PracticeAudio {
  m4a: Buffer;
  durationSec: number;
}

/**
 * The practice version (mono AAC .m4a, as the phone records) of each clip in
 * [clipIds], built once into the fixtures folder; by clip id.
 */
export async function loadPracticeAudio(clipIds: Iterable<string>): Promise<Map<string, PracticeAudio>> {
  const { buildPracticeM4a } = await import("../../test_audio/build_fixtures.mjs");
  const byId = new Map(clips.map((clip) => [clip.id, clip]));
  const audio = new Map<string, PracticeAudio>();
  for (const id of new Set(clipIds)) {
    const clip = byId.get(id);
    if (!clip) throw new Error(`no clip "${id}" in test_audio.json`);
    const { path, durationSec } = buildPracticeM4a(clip.file);
    audio.set(id, { m4a: readFileSync(path), durationSec: Math.round(durationSec) });
  }
  return audio;
}
