import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  Timestamp,
  updateDoc,
  writeBatch,
  type Firestore,
} from "firebase/firestore";
import { afterAll, beforeAll, beforeEach, describe, test } from "vitest";
import { anonymous, as, createTestEnv, seedFixtures } from "./fixtures.js";

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await createTestEnv();
});
beforeEach(() => seedFixtures(env));
afterAll(() => env.cleanup());

function note(over: Record<string, unknown> = {}) {
  return {
    teacherId: "t1",
    note: "انتبه لأحكام المدّ",
    atSecond: 42,
    rating: 4,
    createdAt: serverTimestamp(),
    ...over,
  };
}

/** What FeedbackRepository.add sends: the note and unreadFeedback, in one batch. */
function addNote(db: Firestore, recordingId: string, data: Record<string, unknown>) {
  const batch = writeBatch(db);
  batch.set(doc(collection(db, `recordings/${recordingId}/feedback`)), data);
  batch.update(doc(db, `recordings/${recordingId}`), { unreadFeedback: true });
  return batch.commit();
}

describe("reading feedback", () => {
  test("the recording's student, teacher and admins read it", async () => {
    const notes = (db: Firestore) =>
      getDocs(query(collection(db, "recordings/r-s1/feedback"), orderBy("createdAt")));
    await assertSucceeds(notes(as(env, "s1", "student")));
    await assertSucceeds(notes(as(env, "t1", "teacher")));
    await assertSucceeds(notes(as(env, "admin", "admin")));
    await assertSucceeds(getDoc(doc(as(env, "s1", "student"), "recordings/r-s1/feedback/f1")));
  });

  test("other students, other teachers and anonymous users cannot", async () => {
    await assertFails(getDoc(doc(as(env, "s2", "student"), "recordings/r-s1/feedback/f1")));
    await assertFails(getDoc(doc(as(env, "t2", "teacher"), "recordings/r-s1/feedback/f1")));
    await assertFails(getDoc(doc(anonymous(env), "recordings/r-s1/feedback/f1")));
  });
});

describe("writing feedback", () => {
  test("teacher t1 adds a note on s1's recording, with unreadFeedback in the batch", async () => {
    const db = as(env, "t1", "teacher");
    await assertSucceeds(addNote(db, "r-s1", note()));
    await assertSucceeds(addNote(db, "r-s1", note({ atSecond: null, rating: null })));
  });

  test("teacher t1 cannot add a note on s3's recording", async () => {
    await assertFails(addNote(as(env, "t1", "teacher"), "r-s3", note()));
  });

  test("invalid notes are refused", async () => {
    const db = as(env, "t1", "teacher");
    await assertFails(addNote(db, "r-s2", note({ rating: 6 })));
    await assertFails(addNote(db, "r-s2", note({ rating: 0 })));
    await assertFails(addNote(db, "r-s2", note({ note: "" })));
    await assertFails(addNote(db, "r-s2", note({ note: "x".repeat(2001) })));
    await assertFails(addNote(db, "r-s2", note({ atSecond: -1 })));
    await assertFails(addNote(db, "r-s2", note({ atSecond: 36001 })));
    await assertFails(addNote(db, "r-s2", note({ teacherId: "t2" })));
    await assertFails(addNote(db, "r-s2", note({ createdAt: Timestamp.now() })));
    await assertFails(addNote(db, "r-s2", note({ extra: true })));
  });

  test("students cannot write feedback", async () => {
    await assertFails(addNote(as(env, "s1", "student"), "r-s1", note({ teacherId: "s1" })));
  });

  test("nobody edits a note; the author or an admin deletes it", async () => {
    await assertFails(
      updateDoc(doc(as(env, "t1", "teacher"), "recordings/r-s1/feedback/f1"), { note: "x" }),
    );
    await assertFails(deleteDoc(doc(as(env, "s1", "student"), "recordings/r-s1/feedback/f1")));
    await assertFails(deleteDoc(doc(as(env, "t2", "teacher"), "recordings/r-s1/feedback/f1")));
    await assertSucceeds(deleteDoc(doc(as(env, "t1", "teacher"), "recordings/r-s1/feedback/f1")));
  });

  test("a demoted teacher can no longer read, add or delete notes", async () => {
    const db = as(env, "t1", "student");
    await assertFails(getDoc(doc(db, "recordings/r-s1/feedback/f1")));
    await assertFails(addNote(db, "r-s1", note()));
    await assertFails(deleteDoc(doc(db, "recordings/r-s1/feedback/f1")));
  });

  test("admin deletes any note", async () => {
    await assertSucceeds(deleteDoc(doc(as(env, "admin", "admin"), "recordings/r-s1/feedback/f1")));
  });
});
