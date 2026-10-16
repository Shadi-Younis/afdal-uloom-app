// onRecordingDeleted (a Firestore trigger running in the Functions
// emulator) and the stalled-upload cleanup, on the Firestore and Storage
// emulators. Each test uses its own recording ids, so a trigger still
// running from another test cannot touch its files.
import {Timestamp} from "firebase-admin/firestore";
import {beforeEach, describe, expect, test} from "vitest";

import {runStalledUploadCleanup} from "../src/recordings/cleanup_stalled_uploads.js";
import {bucket, db, eventually, resetFixture} from "./helpers.js";

beforeEach(resetFixture);

const HOUR = 3600_000;

/** A recording of s1 (halaqa h1, teacher t1) at recordings/s1/{id}.mp3. */
async function addRecording(id: string, createdAt = new Date()): Promise<string> {
  const storagePath = `recordings/s1/${id}.mp3`;
  await db.doc(`recordings/${id}`).set({
    studentId: "s1",
    halaqaId: "h1",
    teacherId: "t1",
    uploadedBy: "t1",
    type: "official",
    surahNumber: 1,
    ayahFrom: 1,
    ayahTo: 7,
    storagePath,
    durationSec: null,
    recordedAt: Timestamp.fromDate(createdAt),
    createdAt: Timestamp.fromDate(createdAt),
    unreadFeedback: true,
    reviewed: true,
  });
  return storagePath;
}

const uploadFile = (path: string) =>
  bucket.file(path).save(Buffer.from("fake audio"), {contentType: "audio/mpeg"});

const fileExists = async (path: string) => (await bucket.file(path).exists())[0];

async function addFeedback(recordingId: string, count: number) {
  for (let i = 0; i < count; i++) {
    await db.collection(`recordings/${recordingId}/feedback`).add({
      teacherId: "t1",
      note: `note ${i}`,
      atSecond: i,
      createdAt: Timestamp.now(),
    });
  }
}

const feedbackCount = async (recordingId: string) =>
  (await db.collection(`recordings/${recordingId}/feedback`).count().get()).data().count;

describe("onRecordingDeleted", () => {
  test("removes the audio file and every feedback note", async () => {
    const path = await addRecording("del-1");
    await uploadFile(path);
    await addFeedback("del-1", 3);

    await db.doc("recordings/del-1").delete();

    await eventually(async () => !(await fileExists(path)), "file deleted");
    await eventually(async () => (await feedbackCount("del-1")) === 0, "feedback deleted");
  });

  test("a recording whose file is already gone still loses its feedback", async () => {
    await addRecording("del-2");
    await addFeedback("del-2", 2);

    await db.doc("recordings/del-2").delete();

    await eventually(async () => (await feedbackCount("del-2")) === 0, "feedback deleted");
  });

  test("removes the playback copy too", async () => {
    const path = await addRecording("del-play");
    const copy = "recordings/s1/del-play.play.mp3";
    await uploadFile(path);
    await uploadFile(copy);

    await db.doc("recordings/del-play").delete();

    await eventually(async () => !(await fileExists(copy)), "playback copy deleted");
    await eventually(async () => !(await fileExists(path)), "file deleted");
  });

  test("never deletes a file that is not the recording's own", async () => {
    // A real recording of s2 (practice: never analysed), so the upload
    // trigger keeps its file.
    const other = "recordings/s2/someone-else.mp3";
    await db.doc("recordings/someone-else").set({
      studentId: "s2",
      halaqaId: "h1",
      teacherId: "t1",
      uploadedBy: "s2",
      type: "practice",
      surahNumber: 1,
      ayahFrom: 1,
      ayahTo: 7,
      storagePath: other,
      durationSec: null,
      recordedAt: Timestamp.now(),
      createdAt: Timestamp.now(),
      unreadFeedback: false,
      reviewed: false,
    });
    await uploadFile(other);
    await addRecording("del-3");
    await db.doc("recordings/del-3").update({storagePath: other});
    await addFeedback("del-3", 1);

    await db.doc("recordings/del-3").delete();

    await eventually(async () => (await feedbackCount("del-3")) === 0, "feedback deleted");
    expect(await fileExists(other)).toBe(true);
  });

  test("removes the stems of a two-file recording that were never joined", async () => {
    await addRecording("del-stems");
    const stems = {student: "recordings/s1/del-stems.student.wav", sheikh: "recordings/s1/del-stems.sheikh.mp3"};
    await db.doc("recordings/del-stems").update({source: "stems", stemPaths: stems});
    // Only one arrived: the trigger waits for the other.
    await uploadFile(stems.student);

    await db.doc("recordings/del-stems").delete();

    await eventually(async () => !(await fileExists(stems.student)), "stem deleted");
  });

  test("a stem without its recording (the upload raced a delete) is deleted", async () => {
    const orphan = "recordings/s1/no-such-recording.sheikh.mp3";
    await uploadFile(orphan);
    await eventually(async () => !(await fileExists(orphan)), "orphan stem deleted");
  });

  test("never deletes a stem path that is not the recording's own", async () => {
    // A real practice recording of s1 (never analysed), so its file stays.
    const kept = "recordings/s1/keep-me.m4a";
    await addRecording("keep-me");
    await db.doc("recordings/keep-me").update({type: "practice", uploadedBy: "s1", storagePath: kept});
    await uploadFile(kept);
    await addRecording("del-stems-2");
    await db.doc("recordings/del-stems-2").update({
      source: "stems",
      stemPaths: {student: kept, sheikh: "recordings/s1/del-stems-2.sheikh.mp3"},
    });

    await db.doc("recordings/del-stems-2").delete();

    await new Promise((resolve) => setTimeout(resolve, 3000));
    expect(await fileExists(kept)).toBe(true);
  });

  test("a stem of a one-file recording is ignored, not joined", async () => {
    const path = await addRecording("one-file");
    const stem = "recordings/s1/one-file.student.mp3";
    await uploadFile(stem);
    await new Promise((resolve) => setTimeout(resolve, 3000));
    expect(await fileExists(stem)).toBe(true);
    expect(await fileExists(path)).toBe(false);
    expect((await db.doc("recordings/one-file").get()).get("analysis")).toBeUndefined();
  });

  test("other recordings keep their file and feedback", async () => {
    const keptPath = await addRecording("keep-1");
    await uploadFile(keptPath);
    await addFeedback("keep-1", 2);
    const gonePath = await addRecording("del-4");
    await uploadFile(gonePath);

    await db.doc("recordings/del-4").delete();

    await eventually(async () => !(await fileExists(gonePath)), "file deleted");
    expect(await fileExists(keptPath)).toBe(true);
    expect(await feedbackCount("keep-1")).toBe(2);
  });
});

describe("stalled upload cleanup", () => {
  test("deletes only recordings older than 24 h without a file", async () => {
    const now = new Date();
    const ago = (hours: number) => new Date(now.getTime() - hours * HOUR);
    await addRecording("stalled-1", ago(25));
    await addFeedback("stalled-1", 2);
    const uploadedPath = await addRecording("uploaded-1", ago(48));
    await uploadFile(uploadedPath);
    await addRecording("in-progress-1", ago(2));

    const result = await runStalledUploadCleanup(now);

    // The fixture's r1..r4 are new, so only these two are old enough.
    expect(result).toEqual({checked: 2, deleted: 1});
    expect((await db.doc("recordings/stalled-1").get()).exists).toBe(false);
    expect((await db.doc("recordings/uploaded-1").get()).exists).toBe(true);
    expect((await db.doc("recordings/in-progress-1").get()).exists).toBe(true);
    // The trigger then cleans the deleted recording's feedback.
    await eventually(async () => (await feedbackCount("stalled-1")) === 0, "feedback deleted");
  });

  test("nothing old: nothing checked, nothing deleted", async () => {
    expect(await runStalledUploadCleanup(new Date())).toEqual({checked: 0, deleted: 0});
    expect((await db.collection("recordings").count().get()).data().count).toBe(4);
  });
});
