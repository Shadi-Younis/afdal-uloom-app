// onRecordingUploaded (a Storage trigger running in the Functions emulator)
// on real audio: fixtures built from al-Minshawi's recitations by
// tool/test_audio/build_fixtures.ps1, outside the repo. Skipped, with a
// message, when they are missing. Two-file recordings: stems.test.ts.
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {beforeEach, describe, expect, test} from "vitest";

import {
  addRecording,
  ANALYSIS_TIMEOUT,
  expectMarkersAt,
  feedbackOf,
  fileExists,
  haveFixtures,
  haveStemFixtures,
  manifest,
  recordingData,
  uploadFixture,
  voiceMarkers,
  waitForStatus,
  warnIfMissing,
} from "./audio_fixtures.js";
import {bucket, db, eventually, resetFixture} from "./helpers.js";

warnIfMissing("analysis tests", haveFixtures);

beforeEach(resetFixture);

describe.skipIf(!haveFixtures)("onRecordingUploaded on the al-Minshawi fixtures", () => {
  test(
    "the stereo template: two voice markers where the sheikh spoke, the playback copy, the duration",
    async () => {
      const path = await addRecording("an-stereo");
      await db.collection("recordings/an-stereo/feedback").add({
        teacherId: "t1",
        kind: "text",
        note: "ملاحظة مكتوبة",
        atSecond: 5,
        rating: null,
        createdAt: Timestamp.now(),
      });

      await uploadFixture(manifest!.stereo.file, path);
      await waitForStatus("an-stereo", ["done", "mono", "failed"]);

      const recording = await recordingData("an-stereo");
      expect(recording.analysis).toEqual({
        status: "done",
        segmentCount: 2,
        swapped: false,
        // The fixture's bleed: about -22 dB, each voice far above it.
        bleedDb: expect.closeTo(-22, 0),
        separationDb: expect.any(Number),
      });
      expect(recording.analysis.separationDb).toBeGreaterThan(20);
      expect(recording.playbackPath).toBe("recordings/s1/an-stereo.play.mp3");
      expect(recording.durationSec).toBe(Math.round(manifest!.stereo.durationSec));
      expect(recording.unreadFeedback).toBe(true);

      expectMarkersAt(await voiceMarkers("an-stereo"), manifest!.stereo.sheikhSegments);
      // The written note is kept.
      expect((await feedbackOf("an-stereo")).filter((n) => n.kind === "text")).toHaveLength(1);

      const [copy] = await bucket.file("recordings/s1/an-stereo.play.mp3").getMetadata();
      expect(copy.contentType).toBe("audio/mpeg");
      expect(Number(copy.size)).toBeGreaterThan(0);
    },
    ANALYSIS_TIMEOUT * 2,
  );

  test(
    "running again replaces the voice markers instead of adding more",
    async () => {
      const path = await addRecording("an-rerun");
      await uploadFixture(manifest!.stereo.file, path);
      await waitForStatus("an-rerun", ["done"]);
      const first = await voiceMarkers("an-rerun");
      expect(first).toHaveLength(2);

      // The trigger delivered once more (at least once): the same file again.
      await db.doc("recordings/an-rerun").update({analysis: FieldValue.delete()});
      await uploadFixture(manifest!.stereo.file, path);
      await waitForStatus("an-rerun", ["done"]);

      const second = await voiceMarkers("an-rerun");
      expect(second).toHaveLength(2);
      expect(second.map((m) => m.atSecond)).toEqual(first.map((m) => m.atSecond));
      expect(second.map((m) => m.id)).not.toEqual(first.map((m) => m.id));
    },
    ANALYSIS_TIMEOUT * 3,
  );

  test(
    "a mono file: status mono, no markers, still the playback copy and the duration",
    async () => {
      const path = await addRecording("an-mono");
      await uploadFixture(manifest!.mono.file, path);
      await waitForStatus("an-mono", ["done", "mono", "failed"]);

      const recording = await recordingData("an-mono");
      expect(recording.analysis).toEqual({status: "mono"});
      expect(recording.playbackPath).toBe("recordings/s1/an-mono.play.mp3");
      expect(recording.durationSec).toBe(52);
      expect(recording.unreadFeedback).toBe(false);
      expect(await voiceMarkers("an-mono")).toEqual([]);
      expect(await fileExists("recordings/s1/an-mono.play.mp3")).toBe(true);
    },
    ANALYSIS_TIMEOUT * 2,
  );

  test.skipIf(!haveStemFixtures)(
    "swapped channels (the sheikh on the left): found, swapped back, the same markers",
    async () => {
      const path = await addRecording("an-swapped");
      await uploadFixture(manifest!.swapped!.file, path);
      await waitForStatus("an-swapped", ["done", "mono", "failed"]);

      const recording = await recordingData("an-swapped");
      expect(recording.analysis).toMatchObject({status: "done", segmentCount: 2, swapped: true});
      expect(recording.analysis.bleedDb).toBeCloseTo(-15, 0);
      expectMarkersAt(await voiceMarkers("an-swapped"), manifest!.swapped!.sheikhSegments);
    },
    ANALYSIS_TIMEOUT * 2,
  );

  test(
    "practice recordings are not analysed",
    async () => {
      const path = await addRecording("an-practice", {type: "practice"});
      await uploadFixture(manifest!.stereo.file, path);
      // An official upload after it; once that one is analysed, the
      // practice one has had more than its chance.
      const official = await addRecording("an-after");
      await uploadFixture(manifest!.mono.file, official);
      await waitForStatus("an-after", ["mono", "done", "failed"]);
      await new Promise((resolve) => setTimeout(resolve, 2000));

      const practice = await recordingData("an-practice");
      expect(practice.analysis).toBeUndefined();
      expect(practice.playbackPath).toBeUndefined();
      expect(await voiceMarkers("an-practice")).toEqual([]);
      expect(await fileExists("recordings/s1/an-practice.play.mp3")).toBe(false);
    },
    ANALYSIS_TIMEOUT * 2,
  );
});

describe("onRecordingUploaded without fixtures", () => {
  test("a file that is not audio: failed with a short code, the original kept", async () => {
    const path = await addRecording("an-broken");
    await bucket.file(path).save(Buffer.from("not audio at all"), {contentType: "audio/mpeg"});
    await waitForStatus("an-broken", ["failed", "done", "mono"]);

    const recording = await recordingData("an-broken");
    expect(recording.analysis).toEqual({status: "failed", error: "decode"});
    expect(recording.playbackPath).toBeUndefined();
    expect(await fileExists(path)).toBe(true);
  });

  test("a file without its recording (the upload raced a delete) is deleted", async () => {
    const path = "recordings/s1/no-such-recording.mp3";
    await bucket.file(path).save(Buffer.from("orphan"), {contentType: "audio/mpeg"});
    await eventually(async () => !(await fileExists(path)), "orphan file deleted");
  });
});
