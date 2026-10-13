// Two stems on plain numbers: the envelope meter, the alignment lag and the
// checks before they are joined. No audio and no emulators.
import {describe, expect, test} from "vitest";

import {alignStems, checkStems, EnvelopeMeter} from "../src/lib/stems.js";
import {ANALYSIS} from "../src/lib/voice_analysis.js";

const ROOM = -70;

/** A deterministic "recitation" envelope: words and pauses of varying length and loudness. */
function recitation(frames: number, seed = 7): number[] {
  let state = seed;
  const next = () => {
    state = (state * 1103515245 + 12345) % 2147483648;
    return state / 2147483648;
  };
  const levels: number[] = [];
  while (levels.length < frames) {
    const word = 8 + Math.floor(next() * 40);
    const level = -30 + next() * 15;
    for (let i = 0; i < word; i++) levels.push(level + next() * 3);
    const pause = 3 + Math.floor(next() * 25);
    for (let i = 0; i < pause; i++) levels.push(ROOM + next());
  }
  return levels.slice(0, frames);
}

/** [envelope] heard [shift] frames later in another microphone, [bleedDb] quieter. */
function bled(envelope: readonly number[], shift: number, bleedDb: number): number[] {
  return envelope.map((_, t) => {
    const source = envelope[t - shift];
    return source === undefined ? ROOM : Math.max(ROOM + (t % 3) * 0.2, source + bleedDb);
  });
}

describe("EnvelopeMeter", () => {
  test("one level per 10 ms, the last frame partial", () => {
    const meter = new EnvelopeMeter(1000); // 10 samples per frame
    const pcm = Buffer.alloc(25 * 2);
    for (let i = 0; i < 25; i++) pcm.writeInt16LE(i < 10 ? 16384 : 0, i * 2);
    meter.push(pcm);
    const levels = meter.finish();
    expect(levels).toHaveLength(3);
    expect(levels[0]).toBeCloseTo(-6.02, 1);
    expect(levels[1]).toBe(ANALYSIS.silenceDb);
    expect(meter.durationSeconds).toBeCloseTo(0.025, 5);
  });

  test("chunks may split a sample anywhere", () => {
    const pcm = Buffer.alloc(60);
    for (let i = 0; i < 30; i++) pcm.writeInt16LE(700 * i - 9000, i * 2);
    const whole = new EnvelopeMeter(1000);
    whole.push(pcm);
    const split = new EnvelopeMeter(1000);
    split.push(pcm.subarray(0, 7));
    split.push(pcm.subarray(7, 31));
    split.push(pcm.subarray(31));
    expect(split.finish()).toEqual(whole.finish());
  });
});

describe("alignStems", () => {
  const student = recitation(6000); // one minute
  // The sheikh's microphone: the student's bleed, and the sheikh's own words.
  const sheikhStem = (shift: number) => {
    const levels = bled(student, shift, -15);
    for (let t = 1500 + shift; t < 1900 + shift; t++) levels[t] = -22;
    return levels;
  };

  test.each([0, 3, -5, 10, -10, 50])("finds a lag of %i frames (10 ms each)", (shift) => {
    const alignment = alignStems(student, sheikhStem(shift));
    expect(alignment.lagMs).toBe(shift * 10);
    expect(alignment.correlation).toBeGreaterThan(0.5);
  });

  test("the search stops at ±2 s", () => {
    expect(ANALYSIS.stemsLagSearchSeconds).toBe(2);
    expect(Math.abs(alignStems(student, sheikhStem(250)).lagMs ?? 0)).toBeLessThanOrEqual(2000);
  });

  test("no bleed at all (a noise gate): the lag is unknown, not a guess", () => {
    // Each microphone hears only its own person: the room while the other speaks.
    const gated = student.map((level, t) => (t >= 1500 && t < 1900 ? -22 : ROOM + (level > -50 ? 0 : 0.3)));
    const alignment = alignStems(student, gated);
    expect(alignment.lagMs).toBeNull();
    expect(alignment.correlation).toBeLessThan(ANALYSIS.stemsMinCorrelation);
  });

  test("silence against silence: unknown", () => {
    expect(alignStems(Array(500).fill(-100), Array(500).fill(-100)).lagMs).toBeNull();
  });
});

describe("checkStems", () => {
  const student = recitation(3000);
  const stem = (levels: number[], durationSeconds: number) => ({levels, durationSeconds});

  test("same length, aligned: no problem", () => {
    const check = checkStems(stem(student, 30), stem(bled(student, 2, -15), 30.4));
    expect(check).toEqual({
      lengthDifferenceSeconds: 0.4,
      alignment: expect.objectContaining({lagMs: 20}),
      problem: null,
    });
  });

  test("lengths may differ by 1.0 s, not more", () => {
    expect(checkStems(stem(student, 30), stem(student, 31)).problem).toBeNull();
    expect(checkStems(stem(student, 31), stem(student, 30)).problem).toBeNull();
    const long = checkStems(stem(student, 30), stem(student, 31.01));
    expect(long.problem).toBe("stems_length_mismatch");
    expect(long.alignment).toBeNull();
    expect(checkStems(stem(student, 33), stem(student, 30)).problem).toBe("stems_length_mismatch");
  });

  test("the sheikh may be 100 ms early or late, not more", () => {
    const at = (shift: number) => checkStems(stem(student, 30), stem(bled(student, shift, -15), 30));
    expect(at(10).problem).toBeNull();
    expect(at(-10).problem).toBeNull();
    expect(at(11)).toMatchObject({problem: "stems_misaligned", alignment: {lagMs: 110}});
    expect(at(-50)).toMatchObject({problem: "stems_misaligned", alignment: {lagMs: -500}});
  });
});
