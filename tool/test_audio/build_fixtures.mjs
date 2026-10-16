// Builds the audio fixtures of the recording analysis (onRecordingUploaded)
// from al-Minshawi's recitations, OUTSIDE the repo: by default
// ..\test-audio\fixtures next to the repo (C:\dev\test-audio\fixtures).
// Only Quran recitation is used: no tones, no music, no noise.
//
//   powershell -ExecutionPolicy Bypass -File tool/test_audio/build_fixtures.ps1
//
// - stereo_two_corrections.mp3: the studio template. LEFT (the student)
//   recites al-Fatiha and stops twice; RIGHT (the sheikh) recites part of
//   al-Ikhlas exactly in those two gaps. Each microphone also picks up the
//   other voice faintly (bleed), as in the studio.
// - mono_fatiha.mp3: al-Fatiha in one channel (not exported with the
//   left / right template).
// - stems_student.mp3 / stems_sheikh.mp3: the same session as two stems
//   (Studio One «Export Stems», one mono file per microphone), with louder
//   bleed: each voice at -15 dB in the other microphone.
// - stems_sheikh_long.mp3: the sheikh's stem with 3 s more at the end (not
//   the same export); stems_sheikh_late.mp3: the sheikh's stem 500 ms late.
// - stereo_swapped.mp3: the stems joined the wrong way round (the sheikh
//   LEFT, the student RIGHT).
// - manifest.json: the files and where the sheikh speaks, for the tests.
//
// Also imported by the seed (tool/seed), which uploads the stereo file and
// builds its practice recordings with buildPracticeM4a (practice_*.m4a:
// one recitation in one channel, as the phone app records).
import {execFileSync} from "node:child_process";
import {existsSync, mkdirSync, rmSync, writeFileSync} from "node:fs";
import {createRequire} from "node:module";
import {dirname, join, resolve} from "node:path";
import {fileURLToPath} from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, "..", "..");
const require = createRequire(join(repo, "functions", "package.json"));

/** The al-Minshawi files (tool/seed/download_test_audio.ps1). */
export const minshawiDir = process.env.SEED_AUDIO_DIR ?? resolve(repo, "..", "test-audio", "minshawi");
/** Where the fixtures go. */
export const fixturesDir = process.env.TEST_AUDIO_FIXTURES_DIR ?? resolve(repo, "..", "test-audio", "fixtures");

export const STEREO_FILE = "stereo_two_corrections.mp3";
export const MONO_FILE = "mono_fatiha.mp3";
export const MANIFEST_FILE = "manifest.json";
export const STEMS_STUDENT_FILE = "stems_student.mp3";
export const STEMS_SHEIKH_FILE = "stems_sheikh.mp3";
export const STEMS_SHEIKH_LONG_FILE = "stems_sheikh_long.mp3";
export const STEMS_SHEIKH_LATE_FILE = "stems_sheikh_late.mp3";
export const SWAPPED_FILE = "stereo_swapped.mp3";

const STUDENT = "001.mp3"; // al-Fatiha, the student (left)
const SHEIKH = "112.mp3"; // al-Ikhlas, the sheikh (right)
const RATE = 44100;
/** The other microphone's voice, about -22 dB. */
const BLEED = 0.08;
/** The stems' bleed: -15 dB. */
const STEMS_BLEED_DB = -15;
/** How much longer stems_sheikh_long.mp3 is, and how late stems_sheikh_late.mp3 is. */
const LONG_EXTRA_SECONDS = 3;
const LATE_MS = 500;

/**
 * Where the student stops and the sheikh speaks: after [studentUntil]
 * seconds of al-Fatiha, al-Ikhlas from [sheikhFrom] to [sheikhTo].
 */
const CORRECTIONS = [
  {studentUntil: 14, sheikhFrom: 0, sheikhTo: 4},
  {studentUntil: 30, sheikhFrom: 4, sheikhTo: 9},
];

function ffmpeg() {
  const path = require("ffmpeg-static");
  if (!path || !existsSync(path)) {
    throw new Error("ffmpeg-static is missing: run npm --prefix functions ci");
  }
  return path;
}

/** The duration of [file] in seconds, from ffmpeg's header line. */
function durationOf(file) {
  let output = "";
  try {
    execFileSync(ffmpeg(), ["-hide_banner", "-i", file], {stdio: "pipe"});
  } catch (error) {
    // ffmpeg exits 1 without an output file; the header is still printed.
    output = String(error.stderr);
  }
  const match = /Duration: (\d+):(\d+):([\d.]+)/.exec(output);
  if (!match) throw new Error(`cannot read the duration of ${file}`);
  return Number(match[1]) * 3600 + Number(match[2]) * 60 + Number(match[3]);
}

const round = (seconds) => Math.round(seconds * 100) / 100;

/** The student's and sheikh's timelines, and where the sheikh speaks in the result. */
export function layout(studentSeconds) {
  const student = []; // [from, to) of al-Fatiha, with gaps between
  const sheikh = []; // silence or an al-Ikhlas piece, per gap
  const expected = [];
  let from = 0;
  let at = 0; // position in the fixture
  for (const c of CORRECTIONS) {
    student.push([from, c.studentUntil]);
    at += c.studentUntil - from;
    const length = c.sheikhTo - c.sheikhFrom;
    expected.push({start: round(at), end: round(at + length)});
    sheikh.push({silence: c.studentUntil - from}, {from: c.sheikhFrom, to: c.sheikhTo});
    at += length;
    from = c.studentUntil;
  }
  student.push([from, studentSeconds]);
  const tail = studentSeconds - from;
  sheikh.push({silence: tail});
  return {student, sheikh, expected, duration: round(at + tail)};
}

/**
 * The filter graph of a session played to two microphones with [bleed]
 * (linear gain of the other voice in each one): the student's microphone
 * ends in [Lm], the sheikh's in [Rm]. Input 0 is the student's
 * recitation, input 1 the sheikh's.
 */
function sessionGraph(plan, bleed) {
  const mono = `aformat=sample_fmts=fltp:sample_rates=${RATE}:channel_layouts=mono`;
  const silence = (label, seconds) => `aevalsrc=0:s=${RATE}:d=${seconds.toFixed(3)},${mono}[${label}]`;
  const graph = [];

  // Left: al-Fatiha in pieces, silence while the sheikh speaks.
  graph.push(`[0:a]${mono},asplit=${plan.student.length}${plan.student.map((_, i) => `[sp${i}]`).join("")}`);
  const left = [];
  plan.student.forEach(([from, to], i) => {
    graph.push(`[sp${i}]atrim=${from}:${to},asetpts=PTS-STARTPTS[s${i}]`);
    left.push(`[s${i}]`);
    if (i < CORRECTIONS.length) {
      const c = CORRECTIONS[i];
      graph.push(silence(`gap${i}`, c.sheikhTo - c.sheikhFrom));
      left.push(`[gap${i}]`);
    }
  });
  graph.push(`${left.join("")}concat=n=${left.length}:v=0:a=1[L]`);

  // Right: silence while the student recites, al-Ikhlas in the gaps.
  const pieces = plan.sheikh.filter((p) => p.silence === undefined);
  graph.push(`[1:a]${mono},asplit=${pieces.length}${pieces.map((_, i) => `[kp${i}]`).join("")}`);
  const right = [];
  let k = 0;
  plan.sheikh.forEach((piece, i) => {
    if (piece.silence !== undefined) {
      graph.push(silence(`quiet${i}`, piece.silence));
      right.push(`[quiet${i}]`);
    } else {
      graph.push(`[kp${k}]atrim=${piece.from}:${piece.to},asetpts=PTS-STARTPTS[k${k}]`);
      right.push(`[k${k}]`);
      k++;
    }
  });
  graph.push(`${right.join("")}concat=n=${right.length}:v=0:a=1[R]`);

  // Each microphone hears the other voice faintly.
  graph.push("[L]asplit=2[L1][L2]", "[R]asplit=2[R1][R2]");
  graph.push(`[L1][R1]amix=inputs=2:weights=1 ${bleed}:normalize=0:duration=longest[Lm]`);
  graph.push(`[R2][L2]amix=inputs=2:weights=1 ${bleed}:normalize=0:duration=longest[Rm]`);
  return graph;
}

const MP3 = ["-c:a", "libmp3lame", "-b:a", "128k"];

function runFfmpeg(args) {
  execFileSync(ffmpeg(), ["-hide_banner", "-loglevel", "error", "-y", ...args], {
    stdio: ["ignore", "inherit", "inherit"],
  });
}

function buildStereo(output) {
  const studentFile = join(minshawiDir, STUDENT);
  const plan = layout(durationOf(studentFile));
  const graph = sessionGraph(plan, BLEED);
  graph.push("[Lm][Rm]join=inputs=2:channel_layout=stereo:map=0.0-FL|1.0-FR[out]");
  runFfmpeg([
    "-i", studentFile,
    "-i", join(minshawiDir, SHEIKH),
    "-filter_complex", graph.join(";"),
    "-map", "[out]",
    ...MP3,
    output,
  ]);
  return plan;
}

/**
 * The same session as two mono stems with -15 dB bleed, and its broken
 * variants: too long, late, and joined the wrong way round.
 */
function buildStems() {
  const studentFile = join(minshawiDir, STUDENT);
  const plan = layout(durationOf(studentFile));
  const student = join(fixturesDir, STEMS_STUDENT_FILE);
  const sheikh = join(fixturesDir, STEMS_SHEIKH_FILE);
  runFfmpeg([
    "-i", studentFile,
    "-i", join(minshawiDir, SHEIKH),
    "-filter_complex", sessionGraph(plan, 10 ** (STEMS_BLEED_DB / 20)).join(";"),
    "-map", "[Lm]", ...MP3, student,
    "-map", "[Rm]", ...MP3, sheikh,
  ]);
  runFfmpeg([
    "-i", sheikh,
    "-af", `apad=pad_dur=${LONG_EXTRA_SECONDS}`,
    ...MP3,
    join(fixturesDir, STEMS_SHEIKH_LONG_FILE),
  ]);
  // Late, and cut at the original length: only the timing differs.
  runFfmpeg([
    "-i", sheikh,
    "-af", `adelay=${LATE_MS}:all=1`,
    "-t", plan.duration.toFixed(3),
    ...MP3,
    join(fixturesDir, STEMS_SHEIKH_LATE_FILE),
  ]);
  runFfmpeg([
    "-i", sheikh,
    "-i", student,
    "-filter_complex", "[0:a][1:a]join=inputs=2:channel_layout=stereo:map=0.0-FL|1.0-FR[out]",
    "-map", "[out]",
    ...MP3,
    join(fixturesDir, SWAPPED_FILE),
  ]);
  return plan;
}

function buildMono(output) {
  runFfmpeg(["-i", join(minshawiDir, STUDENT), "-ac", "1", ...MP3, output]);
}

/**
 * A practice recording as the phone app makes it: al-Minshawi's [clipFile]
 * in ONE channel, AAC in an .m4a (the recorder's format on Android / iOS),
 * written to [fixturesDir] once and reused. Returns its path and duration.
 */
export function buildPracticeM4a(clipFile) {
  const source = join(minshawiDir, clipFile);
  if (!existsSync(source)) {
    throw new Error(
      `${source} is missing. Download the recitations first: ` +
        "powershell -ExecutionPolicy Bypass -File tool/seed/download_test_audio.ps1",
    );
  }
  mkdirSync(fixturesDir, {recursive: true});
  const output = join(fixturesDir, `practice_${clipFile.replace(/\.mp3$/, "")}.m4a`);
  if (!existsSync(output)) {
    try {
      execFileSync(
        ffmpeg(),
        [
          "-hide_banner", "-loglevel", "error", "-y",
          "-i", source,
          // -vn: the recitations carry cover art, which .m4a cannot hold.
          "-vn", "-ac", "1", "-c:a", "aac", "-b:a", "64k", "-movflags", "+faststart",
          output,
        ],
        {stdio: ["ignore", "inherit", "inherit"]},
      );
    } catch (error) {
      // Never leave a broken file to be reused by the next run.
      rmSync(output, {force: true});
      throw error;
    }
  }
  return {path: output, durationSec: durationOf(output)};
}

/** Builds every fixture into [fixturesDir] and returns the manifest. */
export function buildFixtures() {
  for (const file of [STUDENT, SHEIKH]) {
    if (!existsSync(join(minshawiDir, file))) {
      throw new Error(
        `${join(minshawiDir, file)} is missing. Download the recitations first: ` +
          "powershell -ExecutionPolicy Bypass -File tool/seed/download_test_audio.ps1",
      );
    }
  }
  mkdirSync(fixturesDir, {recursive: true});
  const plan = buildStereo(join(fixturesDir, STEREO_FILE));
  buildMono(join(fixturesDir, MONO_FILE));
  buildStems();
  const manifest = {
    stereo: {
      file: STEREO_FILE,
      student: "al-Fatiha (left)",
      sheikh: "al-Ikhlas (right)",
      durationSec: plan.duration,
      sheikhSegments: plan.expected,
    },
    mono: {file: MONO_FILE},
    stems: {
      student: STEMS_STUDENT_FILE,
      sheikh: STEMS_SHEIKH_FILE,
      bleedDb: STEMS_BLEED_DB,
      durationSec: plan.duration,
      sheikhSegments: plan.expected,
      sheikhLong: {file: STEMS_SHEIKH_LONG_FILE, extraSeconds: LONG_EXTRA_SECONDS},
      sheikhLate: {file: STEMS_SHEIKH_LATE_FILE, lagMs: LATE_MS},
    },
    swapped: {
      file: SWAPPED_FILE,
      student: "al-Fatiha (right)",
      sheikh: "al-Ikhlas (left)",
      durationSec: plan.duration,
      sheikhSegments: plan.expected,
    },
  };
  writeFileSync(join(fixturesDir, MANIFEST_FILE), JSON.stringify(manifest, null, 2) + "\n");
  return manifest;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const manifest = buildFixtures();
  console.log(`Fixtures in ${fixturesDir}:`);
  console.log(JSON.stringify(manifest, null, 2));
}
