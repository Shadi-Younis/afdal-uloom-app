// Two-file recordings (source "stems") in the emulators: onRecordingUploaded
// waits for both stems, joins them once into the stereo storagePath, runs
// the normal analysis on it and deletes the stems; onRecordingDeleted and
// the stalled-upload cleanup remove stems that were never joined. On the
// al-Minshawi stem fixtures (tool/test_audio); skipped without them.
import {Timestamp} from "firebase-admin/firestore";
import {beforeEach, describe, expect, test} from "vitest";

import {claimStemsJoin} from "../src/recordings/merge_stems.js";
import {runStalledUploadCleanup} from "../src/recordings/cleanup_stalled_uploads.js";
import {
  addRecording,
  analysisOf,
  analysisStatus,
  ANALYSIS_TIMEOUT,
  expectMarkersAt,
  fileExists,
  filesOf,
  haveStemFixtures,
  manifest,
  recordingData,
  uploadFixture,
  voiceMarkers,
  waitForStatus,
  warnIfMissing,
} from "./audio_fixtures.js";
import {db, eventually, resetFixture} from "./helpers.js";

warnIfMissing("two-file (stems) tests", haveStemFixtures);

beforeEach(resetFixture);

/** Joining, then analysing: two runs of ffmpeg on a one-minute session. */
const STEMS_TIMEOUT = ANALYSIS_TIMEOUT * 2;
const HOUR = 3600_000;

const stemPathsOf = (id: string) => ({
  student: `recordings/s1/${id}.student.mp3`,
  sheikh: `recordings/s1/${id}.sheikh.mp3`,
});

/** A two-file recording of s1: its joined file recordings/s1/{id}.mp3, its stems .student/.sheikh.mp3. */
async function addStemsRecording(id: string, createdAt = new Date()) {
  const stems = stemPathsOf(id);
  const joined = await addRecording(id, {createdAt, extra: {source: "stems", stemPaths: stems}});
  return {joined, ...stems};
}

const playbackOf = (id: string) => `recordings/s1/${id}.play.mp3`;

/** The finished two-file recording: what any stereo upload of the session gives. */
async function expectJoinedAndAnalysed(id: string) {
  const recording = await recordingData(id);
  expect(recording.analysis).toMatchObject({status: "done", segmentCount: 2, swapped: false});
  // The stems' bleed (-15 dB) is measured, not taken for the sheikh.
  expect(recording.analysis.bleedDb).toBeCloseTo(manifest!.stems!.bleedDb, 0);
  expect(recording.analysis.separationDb).toBeGreaterThan(20);
  expect(Math.abs(recording.analysis.stemsLagMs)).toBeLessThanOrEqual(20);
  expect(recording.playbackPath).toBe(playbackOf(id));
  expect(recording.durationSec).toBe(Math.round(manifest!.stems!.durationSec));
  expect(recording.unreadFeedback).toBe(true);
  expectMarkersAt(await voiceMarkers(id), manifest!.stems!.sheikhSegments);
  // The stems are deleted once joined; the joined file and its copy stay.
  await eventually(
    async () => JSON.stringify(await filesOf(id)) === JSON.stringify([`recordings/s1/${id}.mp3`, playbackOf(id)]),
    `${id}: only the joined file and its copy left`,
  );
}

describe.skipIf(!haveStemFixtures)("two-file recordings", () => {
  test(
    "the student's stem first: waits for the sheikh's, then joins and analyses",
    async () => {
      const paths = await addStemsRecording("st-order-1");
      await uploadFixture(manifest!.stems!.student, paths.student);
      // Waiting: nothing joined, no analysis yet.
      await new Promise((resolve) => setTimeout(resolve, 3000));
      expect(await analysisStatus("st-order-1")).toBeUndefined();
      expect(await fileExists(paths.joined)).toBe(false);

      await uploadFixture(manifest!.stems!.sheikh, paths.sheikh);
      await waitForStatus("st-order-1", ["done", "mono", "failed"], STEMS_TIMEOUT);
      await expectJoinedAndAnalysed("st-order-1");
    },
    STEMS_TIMEOUT * 2,
  );

  test(
    "the sheikh's stem first: the same result",
    async () => {
      const paths = await addStemsRecording("st-order-2");
      await uploadFixture(manifest!.stems!.sheikh, paths.sheikh);
      await new Promise((resolve) => setTimeout(resolve, 2000));
      expect(await analysisStatus("st-order-2")).toBeUndefined();
      await uploadFixture(manifest!.stems!.student, paths.student);
      await waitForStatus("st-order-2", ["done", "mono", "failed"], STEMS_TIMEOUT);
      await expectJoinedAndAnalysed("st-order-2");
    },
    STEMS_TIMEOUT * 2,
  );

  test(
    "both stems at once: joined once, the same result",
    async () => {
      const paths = await addStemsRecording("st-together");
      await Promise.all([
        uploadFixture(manifest!.stems!.student, paths.student),
        uploadFixture(manifest!.stems!.sheikh, paths.sheikh),
      ]);
      await waitForStatus("st-together", ["done", "mono", "failed"], STEMS_TIMEOUT);
      await expectJoinedAndAnalysed("st-together");
      // A second join would start the analysis again: still done, still two markers.
      await new Promise((resolve) => setTimeout(resolve, 3000));
      expect(await analysisStatus("st-together")).toBe("done");
      expect(await voiceMarkers("st-together")).toHaveLength(2);
    },
    STEMS_TIMEOUT * 2,
  );

  test(
    "lengths differ by more than a second: failed, nothing joined, the stems kept",
    async () => {
      const paths = await addStemsRecording("st-long");
      await uploadFixture(manifest!.stems!.student, paths.student);
      await uploadFixture(manifest!.stems!.sheikhLong.file, paths.sheikh);
      await waitForStatus("st-long", ["failed", "done", "mono"], STEMS_TIMEOUT);

      expect(await analysisOf("st-long")).toEqual({status: "failed", error: "stems_length_mismatch"});
      expect(await filesOf("st-long")).toEqual([paths.sheikh, paths.student].sort());
      expect((await recordingData("st-long")).playbackPath).toBeUndefined();
    },
    STEMS_TIMEOUT,
  );

  test(
    "the sheikh's stem 500 ms late: failed as misaligned, the lag stored",
    async () => {
      const paths = await addStemsRecording("st-late");
      await uploadFixture(manifest!.stems!.student, paths.student);
      await uploadFixture(manifest!.stems!.sheikhLate.file, paths.sheikh);
      await waitForStatus("st-late", ["failed", "done", "mono"], STEMS_TIMEOUT);

      const analysis = await analysisOf("st-late");
      expect(analysis).toMatchObject({status: "failed", error: "stems_misaligned"});
      expect(analysis!.stemsLagMs).toBeGreaterThanOrEqual(manifest!.stems!.sheikhLate.lagMs - 30);
      expect(analysis!.stemsLagMs).toBeLessThanOrEqual(manifest!.stems!.sheikhLate.lagMs + 30);
      expect(await fileExists(paths.joined)).toBe(false);
      expect(await voiceMarkers("st-late")).toEqual([]);
    },
    STEMS_TIMEOUT,
  );

  test(
    "deleted while its stems are joined: every file is gone in the end",
    async () => {
      const paths = await addStemsRecording("st-del-during");
      await Promise.all([
        uploadFixture(manifest!.stems!.student, paths.student),
        uploadFixture(manifest!.stems!.sheikh, paths.sheikh),
      ]);
      await waitForStatus("st-del-during", ["merging", "pending", "done", "failed"], STEMS_TIMEOUT);
      await db.doc("recordings/st-del-during").delete();

      await eventually(
        async () => (await filesOf("st-del-during")).length === 0,
        "no file of the deleted recording left",
        STEMS_TIMEOUT,
      );
      // And none comes back once the join or the analysis would have ended.
      await new Promise((resolve) => setTimeout(resolve, 8000));
      expect(await filesOf("st-del-during")).toEqual([]);
    },
    STEMS_TIMEOUT * 2,
  );

  test(
    "deleted after it was joined: the joined file, its copy and the markers are removed",
    async () => {
      const paths = await addStemsRecording("st-del-after");
      await uploadFixture(manifest!.stems!.student, paths.student);
      await uploadFixture(manifest!.stems!.sheikh, paths.sheikh);
      await waitForStatus("st-del-after", ["done"], STEMS_TIMEOUT);

      await db.doc("recordings/st-del-after").delete();
      await eventually(async () => (await filesOf("st-del-after")).length === 0, "files deleted");
      await eventually(async () => (await voiceMarkers("st-del-after")).length === 0, "markers deleted");
    },
    STEMS_TIMEOUT * 2,
  );
});

describe.skipIf(!haveStemFixtures)("a two-file recording whose second stem never arrives", () => {
  test(
    "stays waiting, then the daily cleanup deletes it and its one stem",
    async () => {
      const now = new Date();
      const paths = await addStemsRecording("st-half", new Date(now.getTime() - 25 * HOUR));
      await uploadFixture(manifest!.stems!.student, paths.student);
      await new Promise((resolve) => setTimeout(resolve, 3000));
      expect(await analysisStatus("st-half")).toBeUndefined();
      expect(await filesOf("st-half")).toEqual([paths.student]);

      const result = await runStalledUploadCleanup(now);
      expect(result).toEqual({checked: 1, deleted: 1});
      expect((await db.doc("recordings/st-half").get()).exists).toBe(false);
      await eventually(async () => (await filesOf("st-half")).length === 0, "the stem deleted");
    },
    STEMS_TIMEOUT,
  );

  test("a recent one is left alone", async () => {
    const now = new Date();
    await addStemsRecording("st-recent", new Date(now.getTime() - 2 * HOUR));
    expect(await runStalledUploadCleanup(now)).toEqual({checked: 0, deleted: 0});
    expect((await db.doc("recordings/st-recent").get()).exists).toBe(true);
  });
});

describe("claimStemsJoin", () => {
  test("of many triggers at the same moment, exactly one joins", async () => {
    await addStemsRecording("st-claim");
    const ref = db.doc("recordings/st-claim");
    const claims = await Promise.all(Array.from({length: 6}, () => claimStemsJoin(ref)));
    expect(claims.filter(Boolean)).toHaveLength(1);
    expect(await analysisOf("st-claim")).toEqual({status: "merging"});
  });

  test("never again once joined or being analysed; again after a failed join", async () => {
    await addStemsRecording("st-claim-2");
    const ref = db.doc("recordings/st-claim-2");
    for (const status of ["merging", "pending", "done", "mono"]) {
      await ref.update({analysis: {status}});
      expect(await claimStemsJoin(ref)).toBe(false);
    }
    await ref.update({analysis: {status: "failed", error: "stems_internal"}});
    expect(await claimStemsJoin(ref)).toBe(true);
  });

  test("not for a deleted recording", async () => {
    expect(await claimStemsJoin(db.doc("recordings/no-such-recording"))).toBe(false);
  });

  test("leaves the other fields alone", async () => {
    await addStemsRecording("st-claim-3");
    const ref = db.doc("recordings/st-claim-3");
    await claimStemsJoin(ref);
    const data = await recordingData("st-claim-3");
    expect(data.source).toBe("stems");
    expect(data.createdAt).toBeInstanceOf(Timestamp);
  });
});
