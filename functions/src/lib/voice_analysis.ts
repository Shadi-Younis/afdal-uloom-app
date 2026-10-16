// Finds where the sheikh spoke in a studio recording, from the levels of
// its two channels. Pure functions on numbers: no audio, no Firebase, so
// they are unit-tested on plain arrays (test/voice_analysis.test.ts).
//
// The studio template (Studio One 7): the student's microphone is panned
// fully LEFT, the sheikh's fully RIGHT, and the session is exported as a
// stereo file (or as two stems the server joins into one, left = student).
// While the student recites the sheikh is silent; when the sheikh corrects
// him the student waits.
//
// Real sessions are messier than the template, so nothing below relies on
// fixed levels:
// - each microphone also picks up the other voice (bleed), sometimes only
//   6 dB quieter than in its own microphone;
// - the two microphones may have different gains;
// - the channels may be swapped by mistake.
// The analysis calibrates itself on the recording: the student recites most
// of the session, so the most common right-minus-left difference is the
// student's (his bleed, plus any gain difference), and the sheikh is
// wherever the right channel is clearly above that.

/**
 * Every threshold of the analysis, in one place. Levels are RMS in dBFS
 * (0 dB = a full-scale square wave; digital silence is clamped to
 * silenceDb). D is a frame's right level minus its left level.
 */
export const ANALYSIS = {
  /** Length of one level measurement (50 ms). */
  frameSeconds: 0.05,
  /** The level given to digital silence instead of -Infinity. */
  silenceDb: -100,
  /**
   * Each channel's noise floor is this percentile of its frame levels: both
   * people are silent between phrases, so the low end is the room.
   */
  noiseFloorPercentile: 10,
  /**
   * An active frame (someone speaks): either channel at least this far
   * above that channel's noise floor. The mono check uses the same frames.
   */
  voicedAboveNoiseDb: 12,
  /** A sheikh frame: the right channel at least this far above its noise floor... */
  sheikhAboveNoiseDb: 12,
  /**
   * ...and D at least this far above the student's baseline D. The
   * student's bleed in the sheikh's microphone always sits near the
   * baseline, however loud it is; the sheikh's own voice is far above it
   * (measured on the fixtures: 25..40 dB).
   */
  sheikhOverBleedDb: 12,
  /**
   * The student's baseline D: this percentile of D over the active frames.
   * The student fills most of them, so a low percentile is his even when
   * the sheikh speaks a lot, and it is not pulled up by the sheikh.
   */
  studentBaselinePercentile: 25,
  /**
   * The upper end of D, for the separation: this percentile over the active
   * frames (the sheikh's frames when he spoke at all).
   */
  separationPercentile: 95,
  /**
   * Below this separation (upper end of D minus the baseline) the sheikh
   * never spoke, or the channels do not keep the two voices apart: no voice
   * markers at all rather than wrong ones; the teacher adds notes by hand.
   */
  minSeparationDb: 10,
  /**
   * Swapped channels: the right channel dominates (D > 0) in at least this
   * many times more active frames than the left one (D < 0). The student
   * recites most of the session, so his channel dominates most frames.
   */
  swapDominanceRatio: 1.5,
  /** Frames of the sheikh closer than this are one segment (pauses between his words). */
  mergeGapSeconds: 1.0,
  /** Shorter segments are dropped (a cough, a chair, a page turned). */
  minSegmentSeconds: 0.6,
  /** Each marker starts this much earlier, so the student hears the sheikh's first word. */
  leadInSeconds: 0.3,
  /**
   * Mono check: when the two channels differ by less than this on average
   * over the voiced frames, the file was not exported with the
   * left / right template (or is mono) and has no separate sheikh channel.
   * Measured: one voice recorded in the middle differs by 0.9..1.4 dB
   * (slight imbalance, stereo reverb; al-Minshawi's recitations), the
   * template by about 20 dB (each voice on its own side).
   */
  monoMaxMeanDifferenceDb: 3.0,

  // Two stems (lib/stems.ts), before they are joined into one stereo file.

  /** Their lengths may differ by this much (export tails); more: not the same session. */
  stemsMaxLengthDiffSeconds: 1.0,
  /** Length of one level of the envelopes that align the stems (10 ms). */
  envelopeSeconds: 0.01,
  /** The alignment is searched this far either way. */
  stemsLagSearchSeconds: 2,
  /**
   * The stems may be this far apart (about one syllable is 150 ms); more:
   * the markers would land beside the sheikh's words.
   */
  stemsMaxLagMs: 100,
  /**
   * Below this correlation of the envelopes at their best shift there is no
   * bleed to align on (stems exported with a noise gate): the lag is not
   * measured and the stems are joined as they are.
   */
  stemsMinCorrelation: 0.2,
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

/** Each channel's noise floor (ANALYSIS.noiseFloorPercentile of its levels). */
function noiseFloors(levels: ChannelLevels): {left: number; right: number} {
  return {
    left: percentile(levels.left, ANALYSIS.noiseFloorPercentile),
    right: percentile(levels.right, ANALYSIS.noiseFloorPercentile),
  };
}

/**
 * The indexes of the active frames: someone speaks, i.e. either channel is
 * at least ANALYSIS.voicedAboveNoiseDb above its own noise floor.
 */
function activeFrames(levels: ChannelLevels): number[] {
  const floor = noiseFloors(levels);
  const active: number[] = [];
  for (let i = 0; i < levels.left.length; i++) {
    if (
      levels.left[i] >= floor.left + ANALYSIS.voicedAboveNoiseDb ||
      levels.right[i] >= floor.right + ANALYSIS.voicedAboveNoiseDb
    ) {
      active.push(i);
    }
  }
  return active;
}

/**
 * Whether both channels carry the same audio: a mono file, or a stereo one
 * not exported with the left / right template. Compared over the voiced
 * (active) frames only, since silence is equal in both. A file with no
 * voiced frame at all counts as mono: there is no sheikh channel to find.
 */
export function isMonoLike(levels: ChannelLevels): boolean {
  const voiced = activeFrames(levels);
  let total = 0;
  for (const i of voiced) total += Math.abs(levels.left[i] - levels.right[i]);
  return voiced.length === 0 || total / voiced.length < ANALYSIS.monoMaxMeanDifferenceDb;
}

/** D (right minus left) of every active frame, in order. */
export function activeDifferences(levels: ChannelLevels): number[] {
  return activeFrames(levels).map((i) => levels.right[i] - levels.left[i]);
}

/**
 * Whether the sheikh is on the LEFT: the right channel dominates (D > 0)
 * in at least ANALYSIS.swapDominanceRatio times more active frames than
 * the left one (D < 0). The student recites most of the session, so his
 * channel is the one that dominates most.
 */
export function channelsSwapped(differences: readonly number[]): boolean {
  let left = 0;
  let right = 0;
  for (const d of differences) {
    if (d < 0) left++;
    else if (d > 0) right++;
  }
  return right > 0 && right >= ANALYSIS.swapDominanceRatio * left;
}

/** [levels] with the two channels exchanged. */
export function swapChannels(levels: ChannelLevels): ChannelLevels {
  return {left: levels.right, right: levels.left};
}

/**
 * For each frame, whether the sheikh is speaking in it: the right channel
 * at least ANALYSIS.sheikhAboveNoiseDb above its noise floor, and D at
 * least ANALYSIS.sheikhOverBleedDb above the student's [baselineDb].
 */
export function sheikhFrames(levels: ChannelLevels, baselineDb: number): boolean[] {
  const floor = noiseFloors(levels).right;
  return levels.right.map(
    (right, i) =>
      right >= floor + ANALYSIS.sheikhAboveNoiseDb &&
      right - levels.left[i] >= baselineDb + ANALYSIS.sheikhOverBleedDb,
  );
}

/** What the analysis found in a recording that is not mono. */
export interface VoiceAnalysis {
  /** The sheikh was on the LEFT; the channels were swapped for the analysis. */
  swapped: boolean;
  /**
   * The student's baseline D (after any swap), to 0.1 dB: how loud he is
   * in the sheikh's microphone relative to his own, gain difference
   * included. Typically -25..-6.
   */
  bleedDb: number;
  /** The upper end of D minus the baseline, to 0.1 dB. */
  separationDb: number;
  /** Where the sheikh spoke; none when separationDb < ANALYSIS.minSeparationDb. */
  segments: Segment[];
}

/**
 * Where the sheikh spoke, from the two channels' levels, robust to bleed,
 * gain differences and swapped channels (see the top of this file). Run
 * the mono check (isMonoLike) first: a mono file has no sheikh channel.
 */
export function analyseVoices(levels: ChannelLevels): VoiceAnalysis {
  const swapped = channelsSwapped(activeDifferences(levels));
  const oriented = swapped ? swapChannels(levels) : levels;
  const differences = activeDifferences(oriented);
  if (differences.length === 0) return {swapped, bleedDb: 0, separationDb: 0, segments: []};

  const baseline = percentile(differences, ANALYSIS.studentBaselinePercentile);
  const separation = percentile(differences, ANALYSIS.separationPercentile) - baseline;
  const segments =
    separation < ANALYSIS.minSeparationDb ? [] : segmentsFromFrames(sheikhFrames(oriented, baseline));
  return {swapped, bleedDb: roundDb(baseline), separationDb: roundDb(separation), segments};
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

/** To the millisecond: frame arithmetic in floating point drifts. */
function round(seconds: number): number {
  return Math.round(seconds * 1000) / 1000;
}

/** To 0.1 dB, for the recording document and the logs. */
function roundDb(db: number): number {
  // `|| 0`: never -0.
  return Math.round(db * 10) / 10 || 0;
}
