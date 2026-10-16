// The analysis on plain numbers: frame levels, the mono check, who is who,
// the bleed baseline and the sheikh's segments. No audio and no emulators.
import {describe, expect, test} from "vitest";

import {
  ANALYSIS,
  activeDifferences,
  analyseVoices,
  type ChannelLevels,
  channelsSwapped,
  FrameLevelMeter,
  isMonoLike,
  percentile,
  rmsDb,
  segmentsFromFrames,
  sheikhFrames,
  swapChannels,
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
      voicedAboveNoiseDb: 12,
      sheikhAboveNoiseDb: 12,
      sheikhOverBleedDb: 12,
      studentBaselinePercentile: 25,
      separationPercentile: 95,
      minSeparationDb: 10,
      swapDominanceRatio: 1.5,
      mergeGapSeconds: 1.0,
      minSegmentSeconds: 0.6,
      leadInSeconds: 0.3,
      monoMaxMeanDifferenceDb: 3.0,
      stemsMaxLengthDiffSeconds: 1.0,
      envelopeSeconds: 0.01,
      stemsLagSearchSeconds: 2,
      stemsMaxLagMs: 100,
      stemsMinCorrelation: 0.2,
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
  test("the right channel 12 dB over its floor and D 12 dB over the baseline", () => {
    // Baseline D = -22 (the student's bleed): the sheikh needs D >= -10.
    const flags = sheikhFrames(
      levels(
        [50, ROOM, ROOM], // room: the noise floor
        [10, VOICE, BLEED], // student: D = -22
        [10, BLEED, VOICE], // sheikh: D = +22
        [10, VOICE, VOICE - 11], // D = -11: just under the threshold
        [10, VOICE, VOICE - 10], // D = -10: exactly on it, the sheikh
        [10, ROOM, ROOM + 11], // under floor + 12 dB: noise
      ),
      -22,
    );
    expect(flags.slice(0, 60).some(Boolean)).toBe(false);
    expect(flags.slice(60, 70).every(Boolean)).toBe(true);
    expect(flags.slice(70, 80).some(Boolean)).toBe(false);
    expect(flags.slice(80, 90).every(Boolean)).toBe(true);
    expect(flags.slice(90).some(Boolean)).toBe(false);
  });
});

describe("activeDifferences and channelsSwapped", () => {
  test("D = right - left, only where someone speaks", () => {
    const session = levels([50, ROOM, ROOM], [3, VOICE, BLEED], [2, BLEED, VOICE]);
    expect(activeDifferences(session)).toEqual([-22, -22, -22, 22, 22]);
  });

  test("swapped when the right dominates at least 1.5 times as often", () => {
    const d = (left: number, right: number) => [
      ...Array<number>(left).fill(-20),
      ...Array<number>(right).fill(20),
      0, // neither dominates: not counted
    ];
    expect(channelsSwapped(d(100, 30))).toBe(false); // the template
    expect(channelsSwapped(d(30, 100))).toBe(true);
    expect(channelsSwapped(d(100, 149))).toBe(false);
    expect(channelsSwapped(d(100, 150))).toBe(true);
    expect(channelsSwapped(d(0, 10))).toBe(true);
    expect(channelsSwapped(d(0, 0))).toBe(false);
    expect(channelsSwapped([])).toBe(false);
  });

  test("swapChannels exchanges left and right", () => {
    expect(swapChannels({left: [1, 2], right: [3, 4]})).toEqual({left: [3, 4], right: [1, 2]});
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


describe("analyseVoices", () => {
  /** Two levels played together, in dB. */
  const sumDb = (a: number, b: number) => 10 * Math.log10(10 ** (a / 10) + 10 ** (b / 10));

  // A voice is not one steady level: each frame varies a little (and the
  // room too), so the percentiles see a realistic spread. The student
  // recites in phrases: 1.7 s of voice, then 0.3 s to breathe (15 % of his
  // frames are the room, as between the ayat of a real recitation).
  const voiceJitter = [0, -3, 2, -6, 1, -2, 3, -4];
  const roomJitter = [0, 1, -1, 0.5];
  const phraseFrames = 40;
  const breathFrames = 6;

  type Who = "room" | "student" | "sheikh" | "both";

  interface Studio {
    /** The student in the sheikh's microphone, relative to his own (dB). */
    studentBleed?: number;
    /** The sheikh in the student's microphone, relative to his own (dB). */
    sheikhBleed?: number;
    /** How much hotter the sheikh's microphone is (dB). */
    sheikhGain?: number;
    /** The sheikh exported on the left. */
    swap?: boolean;
  }

  /** Frame levels of a studio session from runs of [frames, who speaks]. */
  function studio(
    {studentBleed = -22, sheikhBleed = -22, sheikhGain = 0, swap = false}: Studio,
    ...runs: Array<[number, Who]>
  ): ChannelLevels {
    const result: ChannelLevels = {left: [], right: []};
    let i = 0;
    for (const [count, who] of runs) {
      for (let n = 0; n < count; n++, i++) {
        const voice = VOICE + voiceJitter[i % voiceJitter.length];
        const room = ROOM + roomJitter[i % roomJitter.length];
        // What each microphone hears: its own person, the other's bleed, the room.
        let left = room;
        let right = room + sheikhGain;
        const breathing = who === "student" && n % phraseFrames >= phraseFrames - breathFrames;
        if ((who === "student" && !breathing) || who === "both") {
          left = sumDb(left, voice);
          right = sumDb(right, voice + studentBleed + sheikhGain);
        }
        if (who === "sheikh" || who === "both") {
          left = sumDb(left, voice + sheikhBleed);
          right = sumDb(right, voice + sheikhGain);
        }
        result.left.push(swap ? right : left);
        result.right.push(swap ? left : right);
      }
    }
    return result;
  }

  // 1 s = 20 frames. The student recites, the sheikh corrects at 12 s (for
  // 4 s) and at 30 s (3 s, with a half-second pause in the middle).
  const TWO_CORRECTIONS: Array<[number, Who]> = [
    [20, "room"],
    [220, "student"],
    [80, "sheikh"], // 12.0 .. 16.0
    [280, "student"],
    [30, "sheikh"], // 30.0 .. 31.5
    [10, "room"],
    [20, "sheikh"], // 32.0 .. 33.0
    [200, "student"],
  ];
  const EXPECTED = [
    {start: 11.7, end: 16.0},
    {start: 29.7, end: 33.0},
  ];

  test("the clean template: both corrections, bleed and separation measured", () => {
    const session = studio({}, ...TWO_CORRECTIONS);
    expect(isMonoLike(session)).toBe(false);
    const result = analyseVoices(session);
    expect(result.segments).toEqual(EXPECTED);
    expect(result.swapped).toBe(false);
    expect(result.bleedDb).toBeCloseTo(-22, 0);
    expect(result.separationDb).toBeGreaterThan(40);
    // The frame length drives the conversion to seconds.
    expect(F).toBe(0.05);
  });

  test.each([-20, -10, -6])(
    "the student's bleed at %i dB in the sheikh's microphone is never the sheikh",
    (studentBleed) => {
      const result = analyseVoices(studio({studentBleed}, ...TWO_CORRECTIONS));
      expect(result.segments).toEqual(EXPECTED);
      expect(result.swapped).toBe(false);
      expect(result.bleedDb).toBeCloseTo(studentBleed, 0);
    },
  );

  test("the sheikh's microphone 10 dB hotter than the student's", () => {
    const result = analyseVoices(studio({sheikhGain: 10}, ...TWO_CORRECTIONS));
    expect(result.segments).toEqual(EXPECTED);
    expect(result.swapped).toBe(false);
    // The student's bleed plus the gain difference.
    expect(result.bleedDb).toBeCloseTo(-12, 0);
  });

  test("swapped channels: found, swapped back, the same markers", () => {
    const session = studio({swap: true}, ...TWO_CORRECTIONS);
    const result = analyseVoices(session);
    expect(result.swapped).toBe(true);
    expect(result.segments).toEqual(EXPECTED);
    expect(result.bleedDb).toBeCloseTo(-22, 0);
  });

  test("swapped with loud bleed and a hotter sheikh microphone", () => {
    const session = studio({swap: true, studentBleed: -14, sheikhGain: 6}, ...TWO_CORRECTIONS);
    const result = analyseVoices(session);
    expect(result.swapped).toBe(true);
    expect(result.segments).toEqual(EXPECTED);
  });

  test.each([-22, -6])(
    "a session where the sheikh never speaks (student bleed %i dB): no markers",
    (studentBleed) => {
      const session = studio({studentBleed}, [20, "room"], [600, "student"], [40, "room"], [400, "student"]);
      expect(isMonoLike(session)).toBe(false);
      const result = analyseVoices(session);
      expect(result.segments).toEqual([]);
      expect(result.separationDb).toBeLessThan(ANALYSIS.minSeparationDb);
      expect(result.swapped).toBe(false);
    },
  );

  test("short overlaps: a word over the student is dropped, a longer one is the sheikh", () => {
    const session = studio(
      {},
      [20, "room"],
      [200, "student"],
      [6, "both"], // 0.3 s: the sheikh says one word while the student goes on
      [200, "student"],
      [30, "both"], // 21.3 .. 22.8: he starts before the student stops
      [40, "sheikh"], // .. 24.8
      [200, "student"],
    );
    expect(analyseVoices(session).segments).toEqual([{start: 21.0, end: 24.8}]);
  });

  test("the mono cases still have no sheikh channel (the mono check runs first)", () => {
    const same = levels([40, ROOM, ROOM], [100, VOICE, VOICE], [20, ROOM, ROOM]);
    expect(isMonoLike(same)).toBe(true);
    expect(isMonoLike(levels([100, -100, -100]))).toBe(true);
    // Even if it ran, identical channels give no separation and no markers.
    expect(analyseVoices(same).segments).toEqual([]);
  });

  test("no active frame at all: nothing found", () => {
    expect(analyseVoices(levels([100, -100, -100]))).toEqual({
      swapped: false,
      bleedDb: 0,
      separationDb: 0,
      segments: [],
    });
  });
});
