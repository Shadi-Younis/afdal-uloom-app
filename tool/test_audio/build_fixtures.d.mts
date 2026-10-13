// Types of build_fixtures.mjs, for the seed (TypeScript).

export const minshawiDir: string;
export const fixturesDir: string;
export const STEREO_FILE: string;
export const MONO_FILE: string;
export const MANIFEST_FILE: string;

export interface FixturesManifest {
  stereo: {
    file: string;
    student: string;
    sheikh: string;
    durationSec: number;
    sheikhSegments: Array<{ start: number; end: number }>;
  };
  mono: { file: string };
}

/** Builds every fixture into fixturesDir and returns the manifest. */
export function buildFixtures(): FixturesManifest;

/**
 * al-Minshawi's [clipFile] as a phone practice recording (mono AAC .m4a),
 * built into fixturesDir once; its path and duration in seconds.
 */
export function buildPracticeM4a(clipFile: string): { path: string; durationSec: number };
