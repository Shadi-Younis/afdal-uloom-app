// Two stems (Studio One «Export Stems»: one file per microphone) and how
// well they line up. Pure functions on numbers: no audio, no Firebase, so
// they are unit-tested on plain arrays (test/stems.test.ts).
//
// Each microphone also picks up the other person (bleed), so both stems
// carry the same recitation, one loud and one faint. Their loudness
// envelopes therefore follow each other, and the shift at which they match
// best is how far one stem is late against the other.

import {ANALYSIS, percentile, rmsDb} from "./voice_analysis.js";

/**
 * Turns 16-bit mono PCM into a loudness envelope: one level (dBFS) per
 * ANALYSIS.envelopeSeconds, chunk by chunk. Chunks may end anywhere, even
 * in the middle of a sample.
 */
export class EnvelopeMeter {
  private readonly samplesPerFrame: number;
  private sum = 0;
  private inFrame = 0;
  private pending: Buffer = Buffer.alloc(0);
  private totalSamples = 0;
  readonly levels: number[] = [];

  constructor(readonly sampleRate: number, frameSeconds: number = ANALYSIS.envelopeSeconds) {
    this.samplesPerFrame = Math.max(1, Math.round(sampleRate * frameSeconds));
  }

  /** Adds raw little-endian s16 mono bytes. */
  push(chunk: Buffer): void {
    const bytes = this.pending.length > 0 ? Buffer.concat([this.pending, chunk]) : chunk;
    const whole = bytes.length - (bytes.length % 2);
    for (let offset = 0; offset < whole; offset += 2) {
      const sample = bytes.readInt16LE(offset) / 32768;
      this.sum += sample * sample;
      this.totalSamples++;
      if (++this.inFrame === this.samplesPerFrame) this.closeFrame();
    }
    this.pending = Buffer.from(bytes.subarray(whole));
  }

  /** Closes the last, partial frame. Call once, after the last push. */
  finish(): number[] {
    if (this.inFrame > 0) this.closeFrame();
    return this.levels;
  }

  /** Decoded length, in seconds. */
  get durationSeconds(): number {
    return this.totalSamples / this.sampleRate;
  }

  private closeFrame(): void {
    this.levels.push(rmsDb(this.sum, this.inFrame));
    this.sum = 0;
    this.inFrame = 0;
  }
}

/** Why two stems cannot be joined; the server stores it as analysis.error. */
export type StemsProblem = "stems_length_mismatch" | "stems_misaligned";

/** A decoded stem: its envelope (one level per ANALYSIS.envelopeSeconds) and length. */
export interface StemEnvelope {
  levels: readonly number[];
  durationSeconds: number;
}

/** Whether two stems are of the same session and line up. */
export interface StemsCheck {
  /** Sheikh minus student, in seconds. */
  lengthDifferenceSeconds: number;
  /** Null when the lengths already differ too much (not measured). */
  alignment: Alignment | null;
  problem: StemsProblem | null;
}

/**
 * Checks two stems before they are joined: their lengths may differ by at
 * most ANALYSIS.stemsMaxLengthDiffSeconds, and the sheikh's may be at
 * most ANALYSIS.stemsMaxLagMs early or late (when the lag can be measured).
 */
export function checkStems(student: StemEnvelope, sheikh: StemEnvelope): StemsCheck {
  const lengthDifferenceSeconds = Math.round((sheikh.durationSeconds - student.durationSeconds) * 1000) / 1000;
  if (Math.abs(lengthDifferenceSeconds) > ANALYSIS.stemsMaxLengthDiffSeconds) {
    return {lengthDifferenceSeconds, alignment: null, problem: "stems_length_mismatch"};
  }
  const alignment = alignStems(student.levels, sheikh.levels);
  const misaligned = alignment.lagMs !== null && Math.abs(alignment.lagMs) > ANALYSIS.stemsMaxLagMs;
  return {lengthDifferenceSeconds, alignment, problem: misaligned ? "stems_misaligned" : null};
}

/** How two stems line up. */
export interface Alignment {
  /**
   * How much later the sheikh's stem is than the student's, in ms (a
   * multiple of ANALYSIS.envelopeSeconds; negative: earlier). Null when the
   * envelopes do not match at any shift (no bleed at all, e.g. stems
   * exported with a noise gate): the lag cannot be measured.
   */
  lagMs: number | null;
  /** How well they match at that shift (Pearson correlation, -1..1). */
  correlation: number;
}

/**
 * The envelope centred on its mean, with everything below its noise floor
 * (ANALYSIS.noiseFloorPercentile) raised to the floor, so the room's hiss
 * and digital silence weigh the same.
 */
function centred(envelope: readonly number[]): number[] {
  const floor = percentile(envelope, ANALYSIS.noiseFloorPercentile);
  const clamped = envelope.map((level) => Math.max(level, floor));
  const mean = clamped.reduce((sum, level) => sum + level, 0) / Math.max(1, clamped.length);
  return clamped.map((level) => level - mean);
}

/**
 * The shift between the [student] and [sheikh] stems' envelopes (one level
 * per ANALYSIS.envelopeSeconds), searched within
 * ±ANALYSIS.stemsLagSearchSeconds: the shift with the highest correlation
 * of the two envelopes over the part where they overlap. Below
 * ANALYSIS.stemsMinCorrelation the lag is unknown (null).
 */
export function alignStems(student: readonly number[], sheikh: readonly number[]): Alignment {
  const x = centred(student);
  const y = centred(sheikh);
  const maxShift = Math.round(ANALYSIS.stemsLagSearchSeconds / ANALYSIS.envelopeSeconds);
  let best = {shift: 0, correlation: -Infinity};
  for (let shift = -maxShift; shift <= maxShift; shift++) {
    // x[t] against y[t + shift]: a positive shift means the sheikh is late.
    const from = Math.max(0, -shift);
    const to = Math.min(x.length, y.length - shift);
    if (to - from < maxShift) continue;
    let xy = 0;
    let xx = 0;
    let yy = 0;
    for (let t = from; t < to; t++) {
      const a = x[t];
      const b = y[t + shift];
      xy += a * b;
      xx += a * a;
      yy += b * b;
    }
    const correlation = xx > 0 && yy > 0 ? xy / Math.sqrt(xx * yy) : 0;
    // Ties go to the smaller shift: a flat match is not "late".
    const better =
      correlation > best.correlation + 1e-12 ||
      (correlation > best.correlation - 1e-12 && Math.abs(shift) < Math.abs(best.shift));
    if (better) best = {shift, correlation};
  }
  if (!Number.isFinite(best.correlation)) return {lagMs: null, correlation: 0};
  const lagMs = Math.round(best.shift * ANALYSIS.envelopeSeconds * 1000) || 0;
  return {
    lagMs: best.correlation >= ANALYSIS.stemsMinCorrelation ? lagMs : null,
    correlation: Math.round(best.correlation * 1000) / 1000,
  };
}
