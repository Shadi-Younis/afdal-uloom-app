// Finds where the sheikh spoke in a studio recording, from the levels of
// its two channels. Pure functions on numbers: no audio, no Firebase, so
// they are unit-tested on plain arrays (test/voice_analysis.test.ts).
//
// The studio template (Studio One 7): the student's microphone is panned
// fully LEFT, the sheikh's fully RIGHT, and the session is exported as a
// stereo file. While the student recites the sheikh is silent; when the
// sheikh corrects him the student waits. So wherever the right channel is
// clearly louder than the left one, the sheikh is speaking.

/**
 * Every threshold of the analysis, in one place. Levels are RMS in dBFS
 * (0 dB = a full-scale square wave; digital silence is clamped to
 * silenceDb).
 */
export const ANALYSIS = {
  /** Length of one level measurement (50 ms). */
  frameSeconds: 0.05,
  /** The level given to digital silence instead of -Infinity. */
  silenceDb: -100,
  /**
   * The right channel's noise floor is this percentile of its frame levels:
   * the sheikh is silent most of the session, so the low end is the room.
   */
  noiseFloorPercentile: 10,
  /** A sheikh frame: the right channel at least this far above its noise floor... */
  sheikhAboveNoiseDb: 12,
  /** ...and at least this much louder than the left (student) channel. */
  sheikhOverStudentDb: 6,
  /** Frames of the sheikh closer than this are one segment (pauses between his words). */
  mergeGapSeconds: 1.0,
  /** Shorter segments are dropped (a cough, a chair, a page turned). */
  minSegmentSeconds: 0.6,
  /** Each marker starts this much earlier, so the student hears the sheikh's first word. */
  leadInSeconds: 0.3,
  /**
   * A voiced frame, for the mono check: either channel at least this far
   * above that channel's noise floor.
   */
  voicedAboveNoiseDb: 12,
  /**
   * Mono check: when the two channels differ by less than this on average
   * over the voiced frames, the file was not exported with the
   * left / right template (or is mono) and has no separate sheikh channel.
   * Measured: one voice recorded in the middle differs by 0.9..1.4 dB
   * (slight imbalance, stereo reverb; al-Minshawi's recitations), the
   * template by about 20 dB (each voice on its own side).
   */
  monoMaxMeanDifferenceDb: 3.0,
} as const;

/** The level of each frame of the two channels, in dBFS. */
export interface ChannelLevels {
  /** The student. */
  left: number[];
  /** The sheikh. */
  right: number[];
}

/** A span of the recording, in seconds. */
export interface Segment {
  start: number;
  end: number;
}

/** The RMS level of [sumOfSquares] over [count] samples in [-1, 1], in dBFS. */
export function rmsDb(sumOfSquares: number, count: number): number {
  if (count === 0 || sumOfSquares <= 0) return ANALYSIS.silenceDb;
  return Math.max(ANALYSIS.silenceDb, 10 * Math.log10(sumOfSquares / count));
}

/**
 * Turns interleaved 16-bit stereo PCM (L, R, L, R, ...) into frame levels,
 * chunk by chunk, so a long session is never held in memory. Chunks may
 * end anywhere, even in the middle of a sample.
 */
export class FrameLevelMeter {
  private readonly samplesPerFrame: number;
  private sumLeft = 0;
  private sumRight = 0;
  private inFrame = 0;
  private pending: Buffer = Buffer.alloc(0);
  private totalSamples = 0;
  readonly levels: ChannelLevels = {left: [], right: []};

  constructor(readonly sampleRate: number, frameSeconds: number = ANALYSIS.frameSeconds) {
    this.samplesPerFrame = Math.max(1, Math.round(sampleRate * frameSeconds));
  }

  /** Adds raw little-endian s16 stereo bytes. */
  push(chunk: Buffer): void {
    const bytes = this.pending.length > 0 ? Buffer.concat([this.pending, chunk]) : chunk;
    const whole = bytes.length - (bytes.length % 4);
    for (let offset = 0; offset < whole; offset += 4) {
      const left = bytes.readInt16LE(offset) / 32768;
      const right = bytes.readInt16LE(offset + 2) / 32768;
      this.sumLeft += left * left;
      this.sumRight += right * right;
      this.totalSamples++;
      if (++this.inFrame === this.samplesPerFrame) this.closeFrame();
    }
    this.pending = Buffer.from(bytes.subarray(whole));
  }

  /** Adds samples given as numbers in [-1, 1] (for tests). */
  pushSamples(left: readonly number[], right: readonly number[]): void {
    const pcm = Buffer.alloc(left.length * 4);
    for (let i = 0; i < left.length; i++) {
      pcm.writeInt16LE(toInt16(left[i]), i * 4);
      pcm.writeInt16LE(toInt16(right[i]), i * 4 + 2);
    }
    this.push(pcm);
  }

  /** Closes the last, partial frame. Call once, after the last push. */
  finish(): ChannelLevels {
    if (this.inFrame > 0) this.closeFrame();
    return this.levels;
  }

  /** Decoded length, in seconds. */
  get durationSeconds(): number {
    return this.totalSamples / this.sampleRate;
  }

  private closeFrame(): void {
    this.levels.left.push(rmsDb(this.sumLeft, this.inFrame));
    this.levels.right.push(rmsDb(this.sumRight, this.inFrame));
    this.sumLeft = 0;
    this.sumRight = 0;
    this.inFrame = 0;
  }
}

function toInt16(value: number): number {
  return Math.max(-32768, Math.min(32767, Math.round(value * 32768)));
}

/** The [percentile] (0..100) of [values], by nearest rank; silence when empty. */
export function percentile(values: readonly number[], percentile: number): number {
  if (values.length === 0) return ANALYSIS.silenceDb;
  const sorted = [...values].sort((a, b) => a - b);
  const rank = Math.ceil((percentile / 100) * sorted.length) - 1;
  return sorted[Math.min(sorted.length - 1, Math.max(0, rank))];
}

/**
 * Whether both channels carry the same audio: a mono file, or a stereo one
 * not exported with the left / right template. Compared over the voiced
 * frames only, since silence is equal in both. A file with no voiced frame
 * at all counts as mono: there is no sheikh channel to find.
 */
export function isMonoLike(levels: ChannelLevels): boolean {
  const floorLeft = percentile(levels.left, ANALYSIS.noiseFloorPercentile);
  const floorRight = percentile(levels.right, ANALYSIS.noiseFloorPercentile);
  let total = 0;
  let voiced = 0;
  for (let i = 0; i < levels.left.length; i++) {
    const left = levels.left[i];
    const right = levels.right[i];
    if (
      left >= floorLeft + ANALYSIS.voicedAboveNoiseDb ||
      right >= floorRight + ANALYSIS.voicedAboveNoiseDb
    ) {
      total += Math.abs(left - right);
      voiced++;
    }
  }
  return voiced === 0 || total / voiced < ANALYSIS.monoMaxMeanDifferenceDb;
}

/** For each frame, whether the sheikh is speaking in it. */
export function sheikhFrames(levels: ChannelLevels): boolean[] {
  const noiseFloor = percentile(levels.right, ANALYSIS.noiseFloorPercentile);
  return levels.right.map(
    (right, i) =>
      right >= noiseFloor + ANALYSIS.sheikhAboveNoiseDb &&
      right - levels.left[i] >= ANALYSIS.sheikhOverStudentDb,
  );
}

/**
 * The sheikh's segments from per-frame flags: runs of frames, merged when
 * the gap between them is shorter than ANALYSIS.mergeGapSeconds, then
 * dropped when shorter than ANALYSIS.minSegmentSeconds, then started
 * ANALYSIS.leadInSeconds earlier (never before 0). In order of time.
 */
export function segmentsFromFrames(
  flags: readonly boolean[],
  frameSeconds: number = ANALYSIS.frameSeconds,
): Segment[] {
  const runs: Segment[] = [];
  let runStart = -1;
  for (let i = 0; i <= flags.length; i++) {
    const on = i < flags.length && flags[i];
    if (on && runStart < 0) runStart = i;
    if (!on && runStart >= 0) {
      runs.push({start: runStart * frameSeconds, end: i * frameSeconds});
      runStart = -1;
    }
  }

  const merged: Segment[] = [];
  for (const run of runs) {
    const last = merged[merged.length - 1];
    // Rounded: 20 frames of 0.05 s are 1.0 s, not 0.9999999.
    if (last && round(run.start - last.end) < ANALYSIS.mergeGapSeconds) {
      last.end = run.end;
    } else {
      merged.push({...run});
    }
  }

  return merged
    .filter((segment) => round(segment.end - segment.start) >= ANALYSIS.minSegmentSeconds)
    .map((segment) => ({
      start: round(Math.max(0, segment.start - ANALYSIS.leadInSeconds)),
      end: round(segment.end),
    }));
}

/** Where the sheikh spoke, from the two channels' levels. */
export function findSheikhSegments(levels: ChannelLevels): Segment[] {
  return segmentsFromFrames(sheikhFrames(levels));
}

/** To the millisecond: frame arithmetic in floating point drifts. */
function round(seconds: number): number {
  return Math.round(seconds * 1000) / 1000;
}
