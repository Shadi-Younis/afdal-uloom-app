// Types of build_fixtures.mjs, for the seed (TypeScript).

export const minshawiDir: string;
export const fixturesDir: string;
export const STEREO_FILE: string;
export const MONO_FILE: string;
export const MANIFEST_FILE: string;
export const STEMS_STUDENT_FILE: string;
export const STEMS_SHEIKH_FILE: string;
export const STEMS_SHEIKH_LONG_FILE: string;
export const STEMS_SHEIKH_LATE_FILE: string;
export const SWAPPED_FILE: string;

export interface ExpectedSegment {
  start: number;
  end: number;
}

export interface FixturesManifest {
  stereo: {
    file: string;
    student: string;
    sheikh: string;
    durationSec: number;
    sheikhSegments: ExpectedSegment[];
  };
  mono: { file: string };
  stems: {
    student: string;
    sheikh: string;
    bleedDb: number;
    durationSec: number;
    sheikhSegments: ExpectedSegment[];
    sheikhLong: { file: string; extraSeconds: number };
    sheikhLate: { file: string; lagMs: number };
  };
  swapped: {
    file: string;
    student: string;
    sheikh: string;
    durationSec: number;
    sheikhSegments: ExpectedSegment[];
  };
}

/** Builds every fixture into fixturesDir and returns the manifest. */
export function buildFixtures(): FixturesManifest;

/**
 * al-Minshawi's [clipFile] as a phone practice recording (mono AAC .m4a),
 * built into fixturesDir once; its path and duration in seconds.
 */
export function buildPracticeM4a(clipFile: string): { path: string; durationSec: number };
