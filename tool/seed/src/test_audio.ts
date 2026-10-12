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

/** Every clip's file and its duration in whole seconds, by clip id; the studio clip too. */
export async function loadClipAudio(): Promise<Map<string, ClipAudio>> {
  const audio = new Map(
    clips.map((clip): [string, ClipAudio] => {
      const mp3 = readFileSync(join(audioDir, clip.file));
      return [clip.id, { mp3, durationSec: Math.round(mp3DurationSeconds(mp3)) }];
    }),
  );
  const { buildFixtures, fixturesDir } = await import("../../test_audio/build_fixtures.mjs");
  const studioPath = join(fixturesDir, studioClip.file);
  if (!existsSync(studioPath)) buildFixtures();
  const mp3 = readFileSync(studioPath);
  audio.set(studioClip.id, { mp3, durationSec: Math.round(mp3DurationSeconds(mp3)) });
  return audio;
}
