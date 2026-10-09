// deleteUser, including the onRecordingDeleted trigger that removes the
// deleted student's files and feedback.
import {Timestamp} from "firebase-admin/firestore";
import {beforeEach, describe, expect, test} from "vitest";

import {
  PASSWORD,
  addSecondAdmin,
  auth,
  bucket,
  callAs,
  db,
  emailFor,
  eventually,
  resetFixture,
  signIn,
} from "./helpers.js";

beforeEach(resetFixture);

const exists = async (path: string) => (await db.doc(path).get()).exists;
const fileExists = async (path: string) => (await bucket.file(path).exists())[0];
const authUserExists = (uid: string) =>
  auth.getUser(uid).then(
    () => true,
    () => false,
  );
const deleteUser = (uid: string, caller = "admin") => callAs(caller, "deleteUser", {uid});

async function addFeedback(recordingId: string, teacherId: string) {
  await db.collection(`recordings/${recordingId}/feedback`).add({
    teacherId,
    note: "note",
    atSecond: null,
    rating: null,
    createdAt: Timestamp.now(),
  });
}

const feedbackCount = async (recordingId: string) =>
  (await db.collection(`recordings/${recordingId}/feedback`).count().get()).data().count;

describe("deleteUser: students", () => {
  test("deletes the account, the users doc and every recording with its file and feedback", async () => {
    for (const id of ["r1", "r2", "r3"]) {
      const studentId = id === "r3" ? "s2" : "s1";
      await bucket.file(`recordings/${studentId}/${id}.mp3`).save(Buffer.from("fake audio"));
      await addFeedback(id, "t1");
    }
    // A file without a document (an interrupted upload) goes too.
    await bucket.file("recordings/s1/orphan.mp3").save(Buffer.from("fake audio"));

    expect(await deleteUser("s1")).toEqual({ok: true, data: {recordingsDeleted: 2}});

    expect(await exists("users/s1")).toBe(false);
    expect(await exists("recordings/r1")).toBe(false);
    expect(await exists("recordings/r2")).toBe(false);
    expect(await authUserExists("s1")).toBe(false);
    await expect(signIn(emailFor("s1"), PASSWORD)).rejects.toThrow();
    expect(await fileExists("recordings/s1/orphan.mp3")).toBe(false);
    for (const id of ["r1", "r2"]) {
      await eventually(async () => !(await fileExists(`recordings/s1/${id}.mp3`)), `${id} file`);
      await eventually(async () => (await feedbackCount(id)) === 0, `${id} feedback`);
    }

    // Another student keeps everything.
    expect(await exists("recordings/r3")).toBe(true);
    expect(await fileExists("recordings/s2/r3.mp3")).toBe(true);
    expect(await feedbackCount("r3")).toBe(1);
    await expect(signIn(emailFor("s2"), PASSWORD)).resolves.toBeTruthy();
  });

  test("a student without recordings: recordingsDeleted 0", async () => {
    await db.doc("recordings/r4").delete();

    expect(await deleteUser("s3")).toEqual({ok: true, data: {recordingsDeleted: 0}});
    expect(await exists("users/s3")).toBe(false);
    expect(await authUserExists("s3")).toBe(false);
  });

  test("re-running after a stop half-way finishes the job", async () => {
    // As if a previous run had deleted the users doc and then stopped.
    await db.doc("users/s2").delete();

    expect(await deleteUser("s2")).toEqual({ok: true, data: {recordingsDeleted: 1}});
    expect(await exists("recordings/r3")).toBe(false);
    expect(await authUserExists("s2")).toBe(false);

    expect(await deleteUser("s2")).toMatchObject({ok: false, code: "not-found"});
  });
});

describe("deleteUser: teachers", () => {
  test("a teacher with halaqat is refused (reason ownsHalaqat) and kept", async () => {
    expect(await deleteUser("t1")).toMatchObject({
      ok: false,
      code: "failed-precondition",
      details: {reason: "ownsHalaqat"},
    });
    expect(await exists("users/t1")).toBe(true);
    await expect(signIn(emailFor("t1"), PASSWORD)).resolves.toBeTruthy();
  });

  test("a teacher without halaqat is deleted (Auth and doc); their feedback stays", async () => {
    await db.doc("halaqat/h2").update({teacherId: "t1"});
    await addFeedback("r4", "t2");

    expect(await deleteUser("t2")).toEqual({ok: true, data: {recordingsDeleted: 0}});

    expect(await exists("users/t2")).toBe(false);
    expect(await authUserExists("t2")).toBe(false);
    await expect(signIn(emailFor("t2"), PASSWORD)).rejects.toThrow();
    expect(await exists("recordings/r4")).toBe(true);
    expect(await feedbackCount("r4")).toBe(1);
  });
});

describe("deleteUser: refusals", () => {
  test("an admin can delete neither another admin nor themselves", async () => {
    await addSecondAdmin();

    for (const uid of ["admin2", "admin"]) {
      expect(await deleteUser(uid), uid).toMatchObject({ok: false, code: "permission-denied"});
    }
    expect(await authUserExists("admin2")).toBe(true);
    expect(await exists("users/admin2")).toBe(true);
    expect(await exists("users/admin")).toBe(true);
  });

  test("a teacher cannot delete their own student", async () => {
    expect(await deleteUser("s1", "t1")).toMatchObject({ok: false, code: "permission-denied"});
    expect(await exists("users/s1")).toBe(true);
  });

  test("unknown user -> not-found", async () => {
    expect(await deleteUser("nobody")).toMatchObject({ok: false, code: "not-found"});
  });
});
