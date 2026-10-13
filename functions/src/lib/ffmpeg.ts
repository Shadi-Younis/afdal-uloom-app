// Runs ffmpeg (the ffmpeg-static binary: Linux in Cloud Functions, Windows
// in the emulator) to decode a recording into channel levels, to make the
// centred copy for listening, and to join two stems into one stereo file.
import {spawn} from "node:child_process";

import ffmpegPath from "ffmpeg-static";

import {EnvelopeMeter} from "./stems.js";
import {type ChannelLevels, FrameLevelMeter} from "./voice_analysis.js";

/**
 * Decoding rate for the analysis. Speech levels need no more, and it keeps
 * a long session cheap to scan.
 */
export const ANALYSIS_SAMPLE_RATE = 16000;

/** The centred copy: one channel, (L + R) / 2, MP3 at this bitrate. */
export const PLAYBACK_BITRATE = "128k";
export const PLAYBACK_SAMPLE_RATE = 44100;

/** The stereo file made from two stems: student left, sheikh right, MP3 at this bitrate. */
export const MERGED_BITRATE = "320k";

export interface DecodedLevels {
  levels: ChannelLevels;
  durationSeconds: number;
}

/** Thrown when ffmpeg cannot read or write a file; [code] goes to analysis.error. */
export class AudioToolError extends Error {
  constructor(readonly code: "decode" | "encode", detail: string) {
    super(`${code}: ${detail}`);
  }
}

/**
 * The levels of both channels of [inputPath], frame by frame, streamed from
 * ffmpeg (16-bit PCM, 2 channels; a mono file is decoded to two equal
 * channels, which the mono check then reports).
 */
export async function decodeLevels(inputPath: string): Promise<DecodedLevels> {
  const meter = new FrameLevelMeter(ANALYSIS_SAMPLE_RATE);
  await run(
    [
      "-i", inputPath,
      "-vn",
      "-ac", "2",
      "-ar", String(ANALYSIS_SAMPLE_RATE),
      "-f", "s16le",
      "-acodec", "pcm_s16le",
      "pipe:1",
    ],
    "decode",
    (chunk) => meter.push(chunk),
  );
  const levels = meter.finish();
  if (levels.left.length === 0) throw new AudioToolError("decode", "no audio");
  return {levels, durationSeconds: meter.durationSeconds};
}

export interface DecodedEnvelope {
  /** One level (dBFS) per ANALYSIS.envelopeSeconds. */
  levels: number[];
  durationSeconds: number;
}

/**
 * The loudness envelope of [inputPath] mixed down to one channel, streamed
 * from ffmpeg (16-bit PCM), and its decoded length.
 */
export async function decodeEnvelope(inputPath: string): Promise<DecodedEnvelope> {
  const meter = new EnvelopeMeter(ANALYSIS_SAMPLE_RATE);
  await run(
    [
      "-i", inputPath,
      "-vn",
      "-ac", "1",
      "-ar", String(ANALYSIS_SAMPLE_RATE),
      "-f", "s16le",
      "-acodec", "pcm_s16le",
      "pipe:1",
    ],
    "decode",
    (chunk) => meter.push(chunk),
  );
  const levels = meter.finish();
  if (levels.length === 0) throw new AudioToolError("decode", "no audio");
  return {levels, durationSeconds: meter.durationSeconds};
}

/**
 * Joins two stems into one stereo MP3 at [outputPath]: [studentPath] mixed
 * down to the LEFT channel, [sheikhPath] to the RIGHT, as the studio
 * template exports it. The shorter one is padded with silence up to
 * [durationSeconds] (the longer one's length).
 */
export async function joinStems(
  studentPath: string,
  sheikhPath: string,
  durationSeconds: number,
  outputPath: string,
): Promise<void> {
  const mono = `aresample=${PLAYBACK_SAMPLE_RATE},aformat=sample_fmts=fltp:channel_layouts=mono`;
  await run(
    [
      "-i", studentPath,
      "-i", sheikhPath,
      "-filter_complex",
      `[0:a]${mono},apad[student];[1:a]${mono},apad[sheikh];` +
        "[student][sheikh]join=inputs=2:channel_layout=stereo:map=0.0-FL|1.0-FR[out]",
      "-map", "[out]",
      // apad never ends: stop at the longer stem.
      "-t", durationSeconds.toFixed(3),
      "-codec:a", "libmp3lame",
      "-b:a", MERGED_BITRATE,
      "-y", outputPath,
    ],
    "encode",
  );
}

/** Writes the centred MP3 copy of [inputPath] to [outputPath]. */
export async function encodePlayback(inputPath: string, outputPath: string): Promise<void> {
  await run(
    [
      "-i", inputPath,
      "-vn",
      // One channel = (L + R) / 2: the student hears both voices in the
      // middle, not one in each ear.
      "-ac", "1",
      "-ar", String(PLAYBACK_SAMPLE_RATE),
      "-codec:a", "libmp3lame",
      "-b:a", PLAYBACK_BITRATE,
      "-y", outputPath,
    ],
    "encode",
  );
}

function run(
  args: string[],
  code: AudioToolError["code"],
  onStdout?: (chunk: Buffer) => void,
): Promise<void> {
  if (!ffmpegPath) throw new AudioToolError(code, "no ffmpeg binary for this platform");
  return new Promise((resolve, reject) => {
    const child = spawn(ffmpegPath as unknown as string, ["-nostdin", "-hide_banner", "-loglevel", "error", ...args], {
      stdio: ["ignore", "pipe", "pipe"],
    });
    let stderr = "";
    child.stdout.on("data", (chunk: Buffer) => onStdout?.(chunk));
    child.stderr.on("data", (chunk: Buffer) => {
      // The last lines are enough to see why it failed.
      stderr = (stderr + chunk.toString()).slice(-2000);
    });
    child.on("error", (error) => reject(new AudioToolError(code, error.message)));
    child.on("close", (exitCode) => {
      if (exitCode === 0) resolve();
      else reject(new AudioToolError(code, `ffmpeg exited with ${exitCode}: ${stderr.trim()}`));
    });
  });
}
