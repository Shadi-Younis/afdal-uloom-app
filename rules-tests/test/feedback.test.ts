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
    kind: "text",
    note: "انتبه لأحكام المدّ",
    atSecond: 42,
    createdAt: serverTimestamp(),
    ...over,
  };
}

/** What FeedbackRepository.update sends: text, updatedAt and unreadFeedback, in one batch. */
function editNote(db: Firestore, recordingId: string, id: string, data: Record<string, unknown>) {
  const batch = writeBatch(db);
  batch.update(doc(db, `recordings/${recordingId}/feedback/${id}`), {
    updatedAt: serverTimestamp(),
    ...data,
  });
  batch.update(doc(db, `recordings/${recordingId}`), { unreadFeedback: true });
  return batch.commit();
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
    await assertSucceeds(addNote(db, "r-s1", note({ atSecond: null })));
  });

  test("no rating any more (Task 12): not even null, by teacher or admin", async () => {
    await assertFails(addNote(as(env, "t1", "teacher"), "r-s1", note({ rating: 4 })));
    await assertFails(addNote(as(env, "t1", "teacher"), "r-s1", note({ rating: null })));
    await assertFails(addNote(as(env, "admin", "admin"), "r-s1", note({ teacherId: "admin", rating: 5 })));
  });

  test("teacher t1 cannot add a note on s3's recording", async () => {
    await assertFails(addNote(as(env, "t1", "teacher"), "r-s3", note()));
  });

  test("invalid notes are refused", async () => {
    const db = as(env, "t1", "teacher");
    await assertFails(addNote(db, "r-s2", note({ note: "" })));
    await assertFails(addNote(db, "r-s2", note({ note: "x".repeat(2001) })));
    await assertFails(addNote(db, "r-s2", note({ atSecond: -1 })));
    await assertFails(addNote(db, "r-s2", note({ atSecond: 36001 })));
    await assertFails(addNote(db, "r-s2", note({ teacherId: "t2" })));
    await assertFails(addNote(db, "r-s2", note({ createdAt: Timestamp.now() })));
    await assertFails(addNote(db, "r-s2", note({ extra: true })));
    await assertFails(addNote(db, "r-s2", note({ updatedAt: serverTimestamp() })));
  });

  test("only written notes: a voice marker or a note without kind is refused", async () => {
    const db = as(env, "t1", "teacher");
    await assertFails(addNote(db, "r-s2", note({ kind: "voice", note: "", endSecond: 50 })));
    await assertFails(addNote(db, "r-s2", note({ kind: "voice" })));
    const { kind: _kind, ...withoutKind } = note();
    await assertFails(addNote(db, "r-s2", withoutKind));
  });

  test("admin adds a note, as its author", async () => {
    const db = as(env, "admin", "admin");
    await assertSucceeds(addNote(db, "r-s3", note({ teacherId: "admin" })));
    await assertFails(addNote(db, "r-s3", note({ teacherId: "t2" })));
  });

  test("students cannot write feedback", async () => {
    await assertFails(addNote(as(env, "s1", "student"), "r-s1", note({ teacherId: "s1" })));
  });

  test("students cannot edit or delete feedback", async () => {
    const db = as(env, "s1", "student");
    await assertFails(editNote(db, "r-s1", "v1", { note: "x" }));
    await assertFails(updateDoc(doc(db, "recordings/r-s1/feedback/f1"), { note: "x" }));
    await assertFails(deleteDoc(doc(db, "recordings/r-s1/feedback/f1")));
    await assertFails(deleteDoc(doc(db, "recordings/r-s1/feedback/v1")));
  });

  test("the recording's teacher edits the text of either kind", async () => {
    const db = as(env, "t1", "teacher");
    await assertSucceeds(editNote(db, "r-s1", "v1", { note: "المدّ ست حركات" }));
    await assertSucceeds(editNote(db, "r-s1", "f1", { note: "أحسنت جداً" }));
    // A note by a former teacher of this halaqa too.
    await assertSucceeds(editNote(db, "r-s1", "f-old", { note: "راجع الآية الخامسة" }));
  });

  test("a voice marker's text may be emptied, a written note's not", async () => {
    const db = as(env, "t1", "teacher");
    await assertSucceeds(editNote(db, "r-s1", "v1", { note: "x" }));
    await assertSucceeds(editNote(db, "r-s1", "v1", { note: "" }));
    await assertFails(editNote(db, "r-s1", "f1", { note: "" }));
    await assertFails(editNote(db, "r-s1", "f1", { note: "x".repeat(2001) }));
  });

  test("an old note that still has a rating stays readable and its text editable", async () => {
    // f1 was written with rating 5 before the stars were removed.
    const student = await getDoc(doc(as(env, "s1", "student"), "recordings/r-s1/feedback/f1"));
    if (student.data()?.rating !== 5) throw new Error("fixture f1 lost its rating");
    await assertSucceeds(editNote(as(env, "t1", "teacher"), "r-s1", "f1", { note: "أحسنت، بارك الله فيك" }));
    await assertSucceeds(editNote(as(env, "admin", "admin"), "r-s1", "f1", { note: "أحسنت" }));
  });

  test("the rating can no longer be written, changed or cleared on an edit", async () => {
    const t1 = as(env, "t1", "teacher");
    await assertFails(editNote(t1, "r-s1", "f1", { note: "x", rating: 3 }));
    await assertFails(editNote(t1, "r-s1", "f1", { note: "x", rating: null }));
    await assertFails(editNote(t1, "r-s1", "v1", { note: "x", rating: 4 }));
    await assertFails(editNote(as(env, "admin", "admin"), "r-s1", "f1", { note: "x", rating: 1 }));
  });

  test("an edit changes nothing but text and updatedAt", async () => {
    const db = as(env, "t1", "teacher");
    await assertFails(editNote(db, "r-s1", "v1", { atSecond: 1 }));
    await assertFails(editNote(db, "r-s1", "v1", { endSecond: 99 }));
    await assertFails(editNote(db, "r-s1", "v1", { kind: "text", note: "x" }));
    await assertFails(editNote(db, "r-s1", "f1", { teacherId: "t2" }));
    await assertFails(editNote(db, "r-s1", "f1", { note: "x", updatedAt: Timestamp.now() }));
    await assertFails(
      updateDoc(doc(db, "recordings/r-s1/feedback/f1"), { note: "x" }),
    );
  });

  test("another teacher cannot edit or delete", async () => {
    const db = as(env, "t2", "teacher");
    await assertFails(editNote(db, "r-s1", "v1", { note: "x" }));
    await assertFails(deleteDoc(doc(db, "recordings/r-s1/feedback/f1")));
    await assertFails(deleteDoc(doc(db, "recordings/r-s1/feedback/v1")));
  });

  test("the recording's teacher deletes any note on it, voice markers too", async () => {
    const db = as(env, "t1", "teacher");
    await assertSucceeds(deleteDoc(doc(db, "recordings/r-s1/feedback/v1")));
    await assertSucceeds(deleteDoc(doc(db, "recordings/r-s1/feedback/f-old")));
    await assertSucceeds(deleteDoc(doc(db, "recordings/r-s1/feedback/f1")));
  });

  test("admin edits any note", async () => {
    await assertSucceeds(editNote(as(env, "admin", "admin"), "r-s1", "v1", { note: "ملاحظة" }));
  });

  test("a demoted teacher can no longer read, add or delete notes", async () => {
    const db = as(env, "t1", "student");
    await assertFails(getDoc(doc(db, "recordings/r-s1/feedback/f1")));
    await assertFails(addNote(db, "r-s1", note()));
    await assertFails(editNote(db, "r-s1", "v1", { note: "x" }));
    await assertFails(deleteDoc(doc(db, "recordings/r-s1/feedback/f1")));
  });

  test("admin deletes any note", async () => {
    await assertSucceeds(deleteDoc(doc(as(env, "admin", "admin"), "recordings/r-s1/feedback/f1")));
  });
});
