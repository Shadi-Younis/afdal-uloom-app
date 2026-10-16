// Runs the server's recording analysis on files on this PC, to see what
// onRecordingUploaded would find, without uploading anything. Reuses the
// compiled functions code (functions/lib), so the answer is the server's.
//
//   npm --prefix functions run analyse -- <stereo-file>
//   npm --prefix functions run analyse -- --student <file> --sheikh <file>
//
// Two-file mode checks the stems exactly as the server does (lengths,
// alignment lag), joins them the same way (student left, sheikh right) into
// a temporary file, then analyses that file. Documented in docs/ANALYSE_AUDIO.md.
import {mkdtemp, rm} from "node:fs/promises";
import {existsSync} from "node:fs";
import {tmpdir} from "node:os";
import {dirname, join, resolve} from "node:path";
import {fileURLToPath} from "node:url";

const functionsLib = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..", "functions", "lib", "lib");
const load = (name) => import(new URL(`file:///${join(functionsLib, name).replace(/\\/g, "/")}`).href);
const {analyseFile} = await load("analyse_file.js");
const {decodeEnvelope, joinStems} = await load("ffmpeg.js");
const {checkStems} = await load("stems.js");
const {ANALYSIS} = await load("voice_analysis.js");

const usage =
  "Usage:\n" +
  "  npm --prefix functions run analyse -- <stereo-file>\n" +
  "  npm --prefix functions run analyse -- --student <file> --sheikh <file>";

/** Paths are relative to where npm was started, not to functions/. */
const fromCaller = (path) => resolve(process.env.INIT_CWD ?? process.cwd(), path);

function parseArgs(args) {
  if (args.length === 1 && !args[0].startsWith("--")) return {stereo: fromCaller(args[0])};
  const options = {};
  for (let i = 0; i < args.length; i += 2) {
    if (!["--student", "--sheikh"].includes(args[i]) || args[i + 1] === undefined) return null;
    options[args[i].slice(2)] = fromCaller(args[i + 1]);
  }
  return options.student && options.sheikh ? options : null;
}

/** 75.4 -> "01:15". */
function clock(seconds) {
  const whole = Math.max(0, Math.floor(seconds));
  return `${String(Math.floor(whole / 60)).padStart(2, "0")}:${String(whole % 60).padStart(2, "0")}`;
}

const yesNo = (value) => (value ? "yes" : "no");

function printAnalysis({durationSeconds, voices}) {
  console.log(`Duration:     ${clock(Math.round(durationSeconds))} (${durationSeconds.toFixed(2)} s)`);
  console.log(`Mono:         ${yesNo(voices === null)}`);
  if (voices === null) {
    console.log("Segments:     none (no separate sheikh channel: status mono)");
    return;
  }
  console.log(`Swapped:      ${yesNo(voices.swapped)}`);
  console.log(`bleedDb:      ${voices.bleedDb.toFixed(1)}`);
  const weak = voices.separationDb < ANALYSIS.minSeparationDb ? ` (< ${ANALYSIS.minSeparationDb}: no markers)` : "";
  console.log(`separationDb: ${voices.separationDb.toFixed(1)}${weak}`);
  console.log(`Segments:     ${voices.segments.length}`);
  for (const segment of voices.segments) {
    // As the markers store them: start floored, end rounded to the second.
    const end = Math.max(Math.floor(segment.start), Math.round(segment.end));
    console.log(
      `  ${clock(segment.start)}–${clock(end)}   (${segment.start.toFixed(2)} s – ${segment.end.toFixed(2)} s)`,
    );
  }
}

async function analyseStems(studentPath, sheikhPath) {
  const [student, sheikh] = await Promise.all([decodeEnvelope(studentPath), decodeEnvelope(sheikhPath)]);
  const check = checkStems(student, sheikh);
  console.log(`Student:      ${studentPath} (${student.durationSeconds.toFixed(2)} s)`);
  console.log(`Sheikh:       ${sheikhPath} (${sheikh.durationSeconds.toFixed(2)} s)`);
  console.log(
    `Length diff:  ${check.lengthDifferenceSeconds.toFixed(2)} s (max ${ANALYSIS.stemsMaxLengthDiffSeconds} s)`,
  );
  const alignment = check.alignment;
  if (alignment === null) {
    console.log("Lag:          not measured");
  } else if (alignment.lagMs === null) {
    console.log(`Lag:          unknown (correlation ${alignment.correlation}: no bleed to align on)`);
  } else {
    const sign = alignment.lagMs > 0 ? "+" : "";
    console.log(
      `Lag:          ${sign}${alignment.lagMs} ms, sheikh vs student ` +
        `(max ±${ANALYSIS.stemsMaxLagMs} ms; correlation ${alignment.correlation})`,
    );
  }
  if (check.problem) {
    console.log(`Server:       failed, analysis.error = '${check.problem}'`);
    console.log("              (the stems below are joined anyway, for information)");
  } else {
    console.log("Server:       joins the stems (student LEFT, sheikh RIGHT), then analyses:");
  }
  console.log("");

  const workDir = await mkdtemp(join(tmpdir(), "analyse-"));
  try {
    const merged = join(workDir, "merged.mp3");
    await joinStems(studentPath, sheikhPath, Math.max(student.durationSeconds, sheikh.durationSeconds), merged);
    printAnalysis(await analyseFile(merged));
  } finally {
    await rm(workDir, {recursive: true, force: true});
  }
}

const options = parseArgs(process.argv.slice(2));
if (!options) {
  console.error(usage);
  process.exit(2);
}
for (const path of Object.values(options)) {
  if (!existsSync(path)) {
    console.error(`No such file: ${path}`);
    process.exit(2);
  }
}
try {
  if (options.stereo) {
    console.log(`File:         ${options.stereo}`);
    printAnalysis(await analyseFile(options.stereo));
  } else {
    await analyseStems(options.student, options.sheikh);
  }
} catch (error) {
  console.error(`Cannot analyse: ${error.message}`);
  process.exit(1);
}
