// onRecordingDeleted (a Firestore trigger running in the Functions
// emulator) and the stalled-upload cleanup, on the Firestore and Storage
// emulators. Each test uses its own recording ids, so a trigger still
// running from another test cannot touch its files.
import {Timestamp} from "firebase-admin/firestore";
import {beforeEach, describe, expect, test} from "vitest";

import {runStalledUploadCleanup} from "../src/recordings/cleanup_stalled_uploads.js";
import {bucket, db, resetFixture} from "./helpers.js";

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
      rating: null,
      createdAt: Timestamp.now(),
    });
  }
}

const feedbackCount = async (recordingId: string) =>
  (await db.collection(`recordings/${recordingId}/feedback`).count().get()).data().count;

/** Polls [check] until it holds; triggers run asynchronously. */
async function eventually(check: () => Promise<boolean>, what: string, timeoutMs = 20000) {
  const end = Date.now() + timeoutMs;
  while (Date.now() < end) {
    if (await check()) return;
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error(`Timed out waiting for: ${what}`);
}

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

  test("never deletes a file that is not the recording's own", async () => {
    const other = "recordings/s2/someone-else.mp3";
    await uploadFile(other);
    await addRecording("del-3");
    await db.doc("recordings/del-3").update({storagePath: other});
    await addFeedback("del-3", 1);

    await db.doc("recordings/del-3").delete();

    await eventually(async () => (await feedbackCount("del-3")) === 0, "feedback deleted");
    expect(await fileExists(other)).toBe(true);
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
