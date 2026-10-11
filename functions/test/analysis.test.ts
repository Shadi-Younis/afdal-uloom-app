// onRecordingUploaded (a Storage trigger running in the Functions emulator)
// on real audio: fixtures built from al-Minshawi's recitations by
// tool/test_audio/build_fixtures.ps1, outside the repo. Skipped, with a
// message, when they are missing.
import {existsSync, readFileSync} from "node:fs";
import {join, resolve} from "node:path";

import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {beforeEach, describe, expect, test} from "vitest";

import {ANALYSIS} from "../src/lib/voice_analysis.js";
import {bucket, db, eventually, resetFixture} from "./helpers.js";

const repo = resolve(__dirname, "..", "..");
const fixturesDir =
  process.env.TEST_AUDIO_FIXTURES_DIR ?? resolve(repo, "..", "test-audio", "fixtures");
const manifestPath = join(fixturesDir, "manifest.json");
const haveFixtures = existsSync(manifestPath);
if (!haveFixtures) {
  console.warn(
    `\nSKIPPED analysis tests: no audio fixtures in ${fixturesDir}.\n` +
      "Build them with: powershell -ExecutionPolicy Bypass -File tool/test_audio/build_fixtures.ps1\n",
  );
}

interface Manifest {
  stereo: {file: string; durationSec: number; sheikhSegments: Array<{start: number; end: number}>};
  mono: {file: string};
}
const manifest: Manifest | null = haveFixtures ? JSON.parse(readFileSync(manifestPath, "utf8")) : null;

const ANALYSIS_TIMEOUT = 60_000;

/** A recording of s1 (h1 / t1) at recordings/s1/{id}.mp3, not reviewed. */
async function addRecording(id: string, type: "official" | "practice" = "official"): Promise<string> {
  const storagePath = `recordings/s1/${id}.mp3`;
  await db.doc(`recordings/${id}`).set({
    studentId: "s1",
    halaqaId: "h1",
    teacherId: "t1",
    uploadedBy: type === "official" ? "t1" : "s1",
    type,
    surahNumber: 1,
    ayahFrom: 1,
    ayahTo: 7,
    storagePath,
    durationSec: null,
    recordedAt: Timestamp.now(),
    createdAt: Timestamp.now(),
    unreadFeedback: false,
    reviewed: false,
  });
  return storagePath;
}

const uploadFixture = (file: string, path: string) =>
  bucket.upload(join(fixturesDir, file), {destination: path, contentType: "audio/mpeg"});

const recordingData = async (id: string) => (await db.doc(`recordings/${id}`).get()).data() ?? {};

const analysisStatus = async (id: string) =>
  ((await recordingData(id)).analysis as {status?: string} | undefined)?.status;

const waitForStatus = (id: string, statuses: string[]) =>
  eventually(
    async () => statuses.includes((await analysisStatus(id)) ?? ""),
    `${id} analysed (${statuses.join(" or ")})`,
    ANALYSIS_TIMEOUT,
  );

async function feedbackOf(id: string) {
  const snapshot = await db.collection(`recordings/${id}/feedback`).get();
  return snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()})) as Array<Record<string, unknown>>;
}

const voiceMarkers = async (id: string) =>
  (await feedbackOf(id))
    .filter((note) => note.kind === "voice")
    .sort((a, b) => (a.atSecond as number) - (b.atSecond as number));

const fileExists = async (path: string) => (await bucket.file(path).exists())[0];

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
      expect(recording.analysis).toEqual({status: "done", segmentCount: 2});
      expect(recording.playbackPath).toBe("recordings/s1/an-stereo.play.mp3");
      expect(recording.durationSec).toBe(Math.round(manifest!.stereo.durationSec));
      expect(recording.unreadFeedback).toBe(true);

      const markers = await voiceMarkers("an-stereo");
      expect(markers).toHaveLength(2);
      manifest!.stereo.sheikhSegments.forEach((expected, i) => {
        const marker = markers[i];
        // The marker starts ANALYSIS.leadInSeconds early and is floored to
        // the second: within 0.5 s of that.
        const start = expected.start - ANALYSIS.leadInSeconds;
        expect(marker.atSecond).toBeGreaterThanOrEqual(Math.floor(start - 0.5));
        expect(marker.atSecond).toBeLessThanOrEqual(Math.floor(start + 0.5));
        expect(marker.endSecond).toBeGreaterThanOrEqual(Math.round(expected.end - 0.5));
        expect(marker.endSecond).toBeLessThanOrEqual(Math.round(expected.end + 0.5));
        expect(marker).toMatchObject({teacherId: "t1", note: "", rating: null});
        expect(marker.createdAt).toBeInstanceOf(Timestamp);
      });
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

  test(
    "practice recordings are not analysed",
    async () => {
      const path = await addRecording("an-practice", "practice");
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
