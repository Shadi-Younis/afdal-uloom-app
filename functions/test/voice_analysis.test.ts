// The analysis on plain numbers: frame levels, the mono check and the
// sheikh's segments. No audio and no emulators.
import {describe, expect, test} from "vitest";

import {
  ANALYSIS,
  type ChannelLevels,
  FrameLevelMeter,
  findSheikhSegments,
  isMonoLike,
  percentile,
  rmsDb,
  segmentsFromFrames,
  sheikhFrames,
} from "../src/lib/voice_analysis.js";

const F = ANALYSIS.frameSeconds;

/** Frame levels from runs of [count, left dB, right dB]. */
function levels(...runs: Array<[number, number, number]>): ChannelLevels {
  const result: ChannelLevels = {left: [], right: []};
  for (const [count, left, right] of runs) {
    for (let i = 0; i < count; i++) {
      result.left.push(left);
      result.right.push(right);
    }
  }
  return result;
}

/** Per-frame flags from runs of [count, on]. */
function frames(...runs: Array<[number, boolean]>): boolean[] {
  return runs.flatMap(([count, on]) => Array<boolean>(count).fill(on));
}

// Typical studio levels: the room at -70 dB, a voice at -20 dB, the other
// microphone's bleed at -42 dB.
const ROOM = -70;
const VOICE = -20;
const BLEED = -42;

describe("the thresholds", () => {
  test("are the agreed values", () => {
    expect(ANALYSIS).toEqual({
      frameSeconds: 0.05,
      silenceDb: -100,
      noiseFloorPercentile: 10,
      sheikhAboveNoiseDb: 12,
      sheikhOverStudentDb: 6,
      mergeGapSeconds: 1.0,
      minSegmentSeconds: 0.6,
      leadInSeconds: 0.3,
      voicedAboveNoiseDb: 12,
      monoMaxMeanDifferenceDb: 3.0,
    });
  });
});

describe("rmsDb and percentile", () => {
  test("full scale is 0 dB, half is about -6 dB, silence is clamped", () => {
    expect(rmsDb(4, 4)).toBe(0);
    expect(rmsDb(0.25 * 4, 4)).toBeCloseTo(-6.02, 2);
    expect(rmsDb(0, 10)).toBe(ANALYSIS.silenceDb);
    expect(rmsDb(1, 0)).toBe(ANALYSIS.silenceDb);
    expect(rmsDb(1e-30, 1)).toBe(ANALYSIS.silenceDb);
  });

  test("percentile by nearest rank", () => {
    const values = [5, 1, 4, 2, 3, 10, 9, 8, 7, 6];
    expect(percentile(values, 10)).toBe(1);
    expect(percentile(values, 50)).toBe(5);
    expect(percentile(values, 100)).toBe(10);
    expect(percentile([], 10)).toBe(ANALYSIS.silenceDb);
  });
});

describe("FrameLevelMeter", () => {
  test("one level per 50 ms per channel, the last frame partial", () => {
    const meter = new FrameLevelMeter(100); // 5 samples per frame
    const n = 12;
    meter.pushSamples(Array(n).fill(0.5), Array(n).fill(0));
    const result = meter.finish();
    expect(result.left).toHaveLength(3);
    expect(result.left[0]).toBeCloseTo(-6.02, 1);
    expect(result.left[2]).toBeCloseTo(-6.02, 1); // 2 samples, same level
    expect(result.right).toEqual([-100, -100, -100]);
    expect(meter.durationSeconds).toBeCloseTo(0.12, 5);
  });

  test("chunks may split a sample anywhere", () => {
    const whole = new FrameLevelMeter(100);
    const split = new FrameLevelMeter(100);
    const pcm = Buffer.alloc(40);
    for (let i = 0; i < 10; i++) {
      pcm.writeInt16LE(1000 * i, i * 4);
      pcm.writeInt16LE(-500 * i, i * 4 + 2);
    }
    whole.push(pcm);
    split.push(pcm.subarray(0, 3));
    split.push(pcm.subarray(3, 21));
    split.push(pcm.subarray(21));
    expect(split.finish()).toEqual(whole.finish());
  });
});

describe("isMonoLike", () => {
  test("the same audio in both channels is mono", () => {
    expect(isMonoLike(levels([40, ROOM, ROOM], [100, VOICE, VOICE], [20, ROOM, ROOM]))).toBe(true);
  });

  test("channels a little apart (< 3 dB on average) are still mono", () => {
    // A voice in the middle with some stereo reverb.
    expect(isMonoLike(levels([40, ROOM, ROOM], [100, VOICE, VOICE + 1.4]))).toBe(true);
    expect(isMonoLike(levels([40, ROOM, ROOM], [100, VOICE, VOICE - 2.9]))).toBe(true);
    expect(isMonoLike(levels([40, ROOM, ROOM], [100, VOICE, VOICE - 3.1]))).toBe(false);
  });

  test("the left / right template is not mono", () => {
    const studio = levels(
      [40, ROOM, ROOM],
      [100, VOICE, BLEED], // the student recites
      [30, BLEED, VOICE], // the sheikh corrects
      [100, VOICE, BLEED],
    );
    expect(isMonoLike(studio)).toBe(false);
  });

  test("a silent file has no sheikh channel: mono", () => {
    expect(isMonoLike(levels([100, -100, -100]))).toBe(true);
  });
});

describe("sheikhFrames", () => {
  test("the right channel 12 dB over its floor and 6 dB over the left", () => {
    const flags = sheikhFrames(
      levels(
        [50, ROOM, ROOM], // room: the noise floor
        [10, VOICE, BLEED], // student
        [10, BLEED, VOICE], // sheikh
        [10, VOICE, VOICE - 1], // both at once: not clearly the sheikh
        [10, VOICE - 6, VOICE], // exactly 6 dB louder: the sheikh
        [10, ROOM, ROOM + 11], // under floor + 12 dB: noise
      ),
    );
    expect(flags.slice(0, 60).some(Boolean)).toBe(false);
    expect(flags.slice(60, 70).every(Boolean)).toBe(true);
    expect(flags.slice(70, 80).some(Boolean)).toBe(false);
    expect(flags.slice(80, 90).every(Boolean)).toBe(true);
    expect(flags.slice(90).some(Boolean)).toBe(false);
  });
});

describe("segmentsFromFrames", () => {
  test("one run becomes a segment starting 0.3 s earlier", () => {
    // Frames 100..129: 5.0 s .. 6.5 s.
    expect(segmentsFromFrames(frames([100, false], [30, true], [50, false]))).toEqual([
      {start: 4.7, end: 6.5},
    ]);
  });

  test("gaps under 1.0 s merge, gaps of 1.0 s do not", () => {
    const merged = frames([100, false], [20, true], [19, false], [20, true], [40, false]);
    expect(segmentsFromFrames(merged)).toEqual([{start: 4.7, end: 7.95}]);

    const apart = frames([100, false], [20, true], [20, false], [20, true], [40, false]);
    expect(segmentsFromFrames(apart)).toEqual([
      {start: 4.7, end: 6.0},
      {start: 6.7, end: 8.0},
    ]);
  });

  test("segments under 0.6 s are dropped, 0.6 s is kept", () => {
    expect(segmentsFromFrames(frames([100, false], [11, true], [100, false]))).toEqual([]);
    expect(segmentsFromFrames(frames([100, false], [12, true], [100, false]))).toEqual([
      {start: 4.7, end: 5.6},
    ]);
  });

  test("short bits that merge into a long enough segment are kept", () => {
    // Four 0.2 s words with 0.3 s pauses: 1.7 s in all.
    const words = frames(
      [100, false],
      [4, true], [6, false], [4, true], [6, false], [4, true], [6, false], [4, true],
      [100, false],
    );
    expect(segmentsFromFrames(words)).toEqual([{start: 4.7, end: 6.7}]);
  });

  test("the lead-in never goes before the start", () => {
    expect(segmentsFromFrames(frames([2, false], [20, true], [40, false]))).toEqual([
      {start: 0, end: 1.1},
    ]);
  });

  test("a segment running to the end of the file ends there", () => {
    expect(segmentsFromFrames(frames([40, false], [20, true]))).toEqual([{start: 1.7, end: 3.0}]);
  });

  test("no sheikh, no segments", () => {
    expect(segmentsFromFrames(frames([500, false]))).toEqual([]);
    expect(segmentsFromFrames([])).toEqual([]);
  });

  test("frame length is a parameter", () => {
    expect(segmentsFromFrames(frames([10, false], [10, true], [10, false]), 0.1)).toEqual([
      {start: 0.7, end: 2.0},
    ]);
  });
});

describe("findSheikhSegments", () => {
  test("a session with two corrections", () => {
    // 1 s = 20 frames. The student recites, the sheikh corrects at 12 s
    // (for 4 s) and at 30 s (3 s, with a pause in the middle).
    const session = levels(
      [20, ROOM, ROOM],
      [220, VOICE, BLEED],
      [80, BLEED, VOICE], // 12.0 .. 16.0
      [280, VOICE, BLEED],
      [30, BLEED, VOICE], // 30.0 .. 31.5
      [10, ROOM, ROOM], // a half-second pause
      [20, BLEED, VOICE], // 32.0 .. 33.0
      [200, VOICE, BLEED],
    );
    expect(isMonoLike(session)).toBe(false);
    expect(findSheikhSegments(session)).toEqual([
      {start: 11.7, end: 16.0},
      {start: 29.7, end: 33.0},
    ]);
    // The frame length drives the conversion to seconds.
    expect(F).toBe(0.05);
  });
});
