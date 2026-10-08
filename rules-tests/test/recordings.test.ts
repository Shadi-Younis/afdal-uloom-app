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
  setDoc,
  Timestamp,
  updateDoc,
  where,
  type Firestore,
} from "firebase/firestore";
import { afterAll, beforeAll, beforeEach, describe, test } from "vitest";
import { anonymous, as, createTestEnv, recordingDoc, seedFixtures } from "./fixtures.js";

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await createTestEnv();
});
beforeEach(() => seedFixtures(env));
afterAll(() => env.cleanup());

/** What RecordingRepository.create sends: createdAt is the server time. */
function newRecording(id: string, over: Record<string, unknown> = {}) {
  return recordingDoc(id, {
    recordedAt: Timestamp.now(),
    createdAt: serverTimestamp(),
    ...over,
  });
}

/** A practice recording s1 records on the phone. */
function practice(id: string, over: Record<string, unknown> = {}) {
  return newRecording(id, {
    type: "practice",
    uploadedBy: "s1",
    reviewed: false,
    durationSec: null,
    storagePath: `recordings/s1/${id}.m4a`,
    ...over,
  });
}

const create = (db: Firestore, id: string, data: Record<string, unknown>) =>
  setDoc(doc(db, `recordings/${id}`), data);

describe("unauthenticated", () => {
  test("cannot read recordings", async () => {
    const db = anonymous(env);
    await assertFails(getDoc(doc(db, "recordings/r-s1")));
    await assertFails(getDocs(query(collection(db, "recordings"), where("studentId", "==", "s1"))));
  });
});

describe("student s1", () => {
  test("reads own recordings, not s3's", async () => {
    const db = as(env, "s1", "student");
    await assertSucceeds(getDoc(doc(db, "recordings/r-s1")));
    await assertFails(getDoc(doc(db, "recordings/r-s3")));
    await assertFails(getDoc(doc(db, "recordings/r-s2")));
  });

  test("lists own recordings (watchForStudent), not someone else's", async () => {
    const db = as(env, "s1", "student");
    const of = (studentId: string) =>
      query(collection(db, "recordings"), where("studentId", "==", studentId), orderBy("recordedAt", "desc"));
    await assertSucceeds(getDocs(of("s1")));
    await assertFails(getDocs(of("s2")));
    await assertFails(getDocs(collection(db, "recordings")));
  });

  test("creates a practice recording for self", async () => {
    const db = as(env, "s1", "student");
    await assertSucceeds(create(db, "n1", practice("n1")));
    await assertSucceeds(create(db, "n2", practice("n2", { storagePath: "recordings/s1/n2.webm" })));
  });

  test("cannot create for another student or an official recording", async () => {
    const db = as(env, "s1", "student");
    await assertFails(
      create(db, "n1", practice("n1", { studentId: "s2", storagePath: "recordings/s2/n1.m4a" })),
    );
    await assertFails(
      create(db, "n1", practice("n1", { type: "official", reviewed: true })),
    );
    await assertFails(create(db, "n1", practice("n1", { reviewed: true })));
    await assertFails(create(db, "n1", practice("n1", { unreadFeedback: true })));
  });

  test("cannot create with a wrong teacherId or halaqaId", async () => {
    const db = as(env, "s1", "student");
    await assertFails(create(db, "n1", practice("n1", { teacherId: "t2" })));
    await assertFails(create(db, "n1", practice("n1", { halaqaId: "h2", teacherId: "t2" })));
  });

  test("cannot create with a wrong storagePath", async () => {
    const db = as(env, "s1", "student");
    await assertFails(create(db, "n1", practice("n1", { storagePath: "recordings/s1/other.m4a" })));
    await assertFails(create(db, "n1", practice("n1", { storagePath: "recordings/s1/n1.exe" })));
    await assertFails(create(db, "n1", practice("n1", { storagePath: "recordings/s2/n1.m4a" })));
  });

  test("cannot create with an extra field or invalid values", async () => {
    const db = as(env, "s1", "student");
    await assertFails(create(db, "n1", practice("n1", { extra: "x" })));
    await assertFails(create(db, "n1", practice("n1", { surahNumber: 115 })));
    await assertFails(create(db, "n1", practice("n1", { ayahFrom: 0 })));
    await assertFails(create(db, "n1", practice("n1", { ayahFrom: 10, ayahTo: 5 })));
    await assertFails(create(db, "n1", practice("n1", { durationSec: -1 })));
    await assertFails(create(db, "n1", practice("n1", { createdAt: Timestamp.now() })));
    await assertFails(create(db, "n1", practice("n1", { uploadedBy: "t1" })));
    const { reviewed: _reviewed, ...missingKey } = practice("n1");
    await assertFails(create(db, "n1", missingKey));
  });

  test("marks feedback read, but cannot set it unread or change anything else", async () => {
    const db = as(env, "s1", "student");
    const ref = doc(db, "recordings/r-s1");
    await assertFails(updateDoc(ref, { surahNumber: 3 }));
    await assertFails(updateDoc(ref, { unreadFeedback: false, reviewed: false }));
    await assertSucceeds(updateDoc(ref, { unreadFeedback: false }));
    await assertFails(updateDoc(ref, { unreadFeedback: true }));
    await assertFails(updateDoc(doc(db, "recordings/p-s1"), { reviewed: true }));
  });

  test("cannot delete own recording", async () => {
    await assertFails(deleteDoc(doc(as(env, "s1", "student"), "recordings/r-s1")));
  });
});

describe("teacher t1", () => {
  test("lists a student's recordings only with own teacherId filter", async () => {
    const db = as(env, "t1", "teacher");
    const base = [where("studentId", "==", "s1"), orderBy("recordedAt", "desc")] as const;
    await assertSucceeds(
      getDocs(query(collection(db, "recordings"), where("teacherId", "==", "t1"), ...base)),
    );
    await assertFails(getDocs(query(collection(db, "recordings"), ...base)));
  });

  test("lists own pending practice (watchPendingPractice), not t2's", async () => {
    const db = as(env, "t1", "teacher");
    const pending = (teacherId: string) =>
      query(
        collection(db, "recordings"),
        where("teacherId", "==", teacherId),
        where("type", "==", "practice"),
        where("reviewed", "==", false),
        orderBy("createdAt"),
      );
    await assertSucceeds(getDocs(pending("t1")));
    await assertFails(getDocs(pending("t2")));
  });

  test("creates an official recording for s1, not for s3", async () => {
    const db = as(env, "t1", "teacher");
    await assertSucceeds(create(db, "n1", newRecording("n1")));
    await assertFails(
      create(
        db,
        "n2",
        newRecording("n2", { studentId: "s3", halaqaId: "h2", storagePath: "recordings/s3/n2.mp3" }),
      ),
    );
    await assertFails(
      create(
        db,
        "n3",
        newRecording("n3", {
          studentId: "s3",
          halaqaId: "h2",
          teacherId: "t2",
          storagePath: "recordings/s3/n3.mp3",
        }),
      ),
    );
  });

  test("cannot create practice or an unreviewed official recording", async () => {
    const db = as(env, "t1", "teacher");
    await assertFails(create(db, "n1", newRecording("n1", { type: "practice", reviewed: false })));
    await assertFails(create(db, "n1", newRecording("n1", { reviewed: false })));
  });

  test("marks reviewed, but cannot change other fields", async () => {
    const db = as(env, "t1", "teacher");
    await assertSucceeds(updateDoc(doc(db, "recordings/p-s1"), { reviewed: true }));
    await assertFails(updateDoc(doc(db, "recordings/r-s1"), { surahNumber: 3 }));
    await assertFails(updateDoc(doc(db, "recordings/r-s3"), { reviewed: true }));
  });

  test("deletes own student's recording, not s3's", async () => {
    const db = as(env, "t1", "teacher");
    await assertSucceeds(deleteDoc(doc(db, "recordings/r-s2")));
    await assertFails(deleteDoc(doc(db, "recordings/r-s3")));
  });
});

describe("admin", () => {
  test("reads and lists every recording", async () => {
    const db = as(env, "admin", "admin");
    await assertSucceeds(getDoc(doc(db, "recordings/r-s3")));
    await assertSucceeds(getDocs(collection(db, "recordings")));
  });

  test("creates either type with consistent ids", async () => {
    const db = as(env, "admin", "admin");
    const forS3 = { studentId: "s3", halaqaId: "h2", teacherId: "t2", uploadedBy: "admin" };
    await assertSucceeds(
      create(db, "n1", newRecording("n1", { ...forS3, storagePath: "recordings/s3/n1.mp3" })),
    );
    await assertSucceeds(
      create(
        db,
        "n2",
        newRecording("n2", { ...forS3, type: "practice", reviewed: false, storagePath: "recordings/s3/n2.m4a" }),
      ),
    );
    await assertFails(
      create(db, "n3", newRecording("n3", { ...forS3, teacherId: "t1", storagePath: "recordings/s3/n3.mp3" })),
    );
  });

  test("updates review flags and deletes", async () => {
    const db = as(env, "admin", "admin");
    await assertSucceeds(updateDoc(doc(db, "recordings/p-s1"), { reviewed: true }));
    await assertSucceeds(deleteDoc(doc(db, "recordings/r-s3")));
  });
});
