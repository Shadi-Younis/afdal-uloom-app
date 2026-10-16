import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  deleteField,
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
import { afterAll, beforeAll, beforeEach, describe, expect, test } from "vitest";
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

/** An official recording as the upload page sends it: unreviewed. */
function official(id: string, over: Record<string, unknown> = {}) {
  return newRecording(id, { reviewed: false, ...over });
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

  test("cannot delete an official recording, even its own", async () => {
    await assertFails(deleteDoc(doc(as(env, "s1", "student"), "recordings/r-s1")));
  });

  test("deletes own practice recording while not reviewed («حذف التدريب»)", async () => {
    await assertSucceeds(deleteDoc(doc(as(env, "s1", "student"), "recordings/p-s1")));
  });

  test("cannot delete own practice once reviewed, or another student's practice", async () => {
    const db = as(env, "s1", "student");
    await assertFails(deleteDoc(doc(db, "recordings/p-s1-reviewed")));
    await assertFails(deleteDoc(doc(db, "recordings/p-s2")));
  });

  test("a student claim is required: s1's uid with another role cannot delete it", async () => {
    await assertFails(deleteDoc(doc(as(env, "s1", "teacher"), "recordings/p-s1")));
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

  test("lists own unreviewed recordings of either type (watchUnreviewed), not t2's", async () => {
    const db = as(env, "t1", "teacher");
    const pending = (teacherId: string, type: string) =>
      query(
        collection(db, "recordings"),
        where("teacherId", "==", teacherId),
        where("type", "==", type),
        where("reviewed", "==", false),
        orderBy("createdAt"),
      );
    await assertSucceeds(getDocs(pending("t1", "practice")));
    await assertSucceeds(getDocs(pending("t1", "official")));
    await assertFails(getDocs(pending("t2", "official")));
  });

  test("lists the whole review queue, both types (Task 10), not t2's", async () => {
    const db = as(env, "t1", "teacher");
    const queue = (teacherId: string) =>
      query(
        collection(db, "recordings"),
        where("teacherId", "==", teacherId),
        where("reviewed", "==", false),
        orderBy("createdAt"),
      );
    const own = await assertSucceeds(getDocs(queue("t1")));
    expect(own.docs.map((d) => d.id).sort()).toEqual(["p-s1", "p-s2"]);
    await assertFails(getDocs(queue("t2")));
  });

  test("deletes a practice recording of its halaqa, reviewed or not", async () => {
    const db = as(env, "t1", "teacher");
    await assertSucceeds(deleteDoc(doc(db, "recordings/p-s1-reviewed")));
    await assertSucceeds(deleteDoc(doc(db, "recordings/p-s2")));
  });

  test("lists own recordings of this week (watchForTeacherSince), not t2's", async () => {
    const db = as(env, "t1", "teacher");
    const since = (teacherId: string) =>
      query(
        collection(db, "recordings"),
        where("teacherId", "==", teacherId),
        where("recordedAt", ">=", Timestamp.fromDate(new Date("2026-10-10T00:00:00Z"))),
        orderBy("recordedAt", "desc"),
      );
    await assertSucceeds(getDocs(since("t1")));
    await assertFails(getDocs(since("t2")));
  });

  test("cannot create practice, or an official recording marked reviewed", async () => {
    const db = as(env, "t1", "teacher");
    await assertFails(create(db, "n1", official("n1", { type: "practice" })));
    await assertFails(create(db, "n1", official("n1", { reviewed: true })));
  });

  test("toggles reviewed both ways, but cannot change other fields", async () => {
    const db = as(env, "t1", "teacher");
    await assertSucceeds(updateDoc(doc(db, "recordings/p-s1"), { reviewed: true }));
    await assertSucceeds(updateDoc(doc(db, "recordings/r-s1"), { reviewed: false }));
    await assertSucceeds(updateDoc(doc(db, "recordings/r-s1"), { reviewed: true }));
    await assertFails(updateDoc(doc(db, "recordings/r-s1"), { durationSec: 3 }));
    await assertFails(updateDoc(doc(db, "recordings/r-s1"), { reviewed: false, surahNumber: 3 }));
    await assertFails(updateDoc(doc(db, "recordings/r-s3"), { reviewed: true }));
  });

  test("deletes own student's recording, not s3's", async () => {
    const db = as(env, "t1", "teacher");
    await assertSucceeds(deleteDoc(doc(db, "recordings/r-s2")));
    await assertFails(deleteDoc(doc(db, "recordings/r-s3")));
  });
});

describe("official uploads (Task 09)", () => {
  test("a teacher uploads for a student of a halaqa he owns", async () => {
    await assertSucceeds(create(as(env, "t1", "teacher"), "n1", official("n1")));
    await assertSucceeds(
      create(
        as(env, "t1", "teacher"),
        "n2",
        official("n2", { studentId: "s2", storagePath: "recordings/s2/n2.wav" }),
      ),
    );
  });

  test("a teacher cannot upload for another teacher's student", async () => {
    const db = as(env, "t1", "teacher");
    const forS3 = { studentId: "s3", halaqaId: "h2", storagePath: "recordings/s3/n1.mp3" };
    await assertFails(create(db, "n1", official("n1", forS3)));
    await assertFails(create(db, "n1", official("n1", { ...forS3, teacherId: "t2" })));
  });

  test("a student cannot upload an official recording", async () => {
    const db = as(env, "s1", "student");
    await assertFails(create(db, "n1", official("n1", { uploadedBy: "s1" })));
    await assertFails(create(db, "n1", official("n1", { uploadedBy: "s1", reviewed: true })));
  });

  test("the admin uploads for any student", async () => {
    const forS3 = { studentId: "s3", halaqaId: "h2", teacherId: "t2", uploadedBy: "admin" };
    await assertSucceeds(
      create(as(env, "admin", "admin"), "n1", official("n1", { ...forS3, storagePath: "recordings/s3/n1.mp3" })),
    );
  });
});

describe("optional surah and ayat (Task 12)", () => {
  /** official() without some of the three fields. */
  const without = (id: string, keys: string[], over: Record<string, unknown> = {}) => {
    const data = official(id, over);
    for (const key of keys) delete data[key];
    return data;
  };

  test("an official upload may leave out all three, or the ayat", async () => {
    const t1 = as(env, "t1", "teacher");
    await assertSucceeds(create(t1, "n1", without("n1", ["surahNumber", "ayahFrom", "ayahTo"])));
    await assertSucceeds(create(t1, "n2", without("n2", ["ayahFrom", "ayahTo"])));
    // Null is the same as absent.
    await assertSucceeds(create(t1, "n3", official("n3", { surahNumber: null, ayahFrom: null, ayahTo: null })));
    await assertSucceeds(create(t1, "n4", official("n4", { ayahFrom: null, ayahTo: null })));
    const admin = as(env, "admin", "admin");
    await assertSucceeds(
      create(admin, "n5", without("n5", ["surahNumber", "ayahFrom", "ayahTo"], { uploadedBy: "admin" })),
    );
  });

  test("ayat without a surah, one ayah alone, or from > to are refused", async () => {
    const t1 = as(env, "t1", "teacher");
    await assertFails(create(t1, "n1", without("n1", ["surahNumber"])));
    await assertFails(create(t1, "n1", official("n1", { surahNumber: null })));
    await assertFails(create(t1, "n1", without("n1", ["ayahTo"])));
    await assertFails(create(t1, "n1", without("n1", ["ayahFrom"])));
    await assertFails(create(t1, "n1", without("n1", ["surahNumber", "ayahTo"])));
    await assertFails(create(t1, "n1", official("n1", { ayahFrom: 21, ayahTo: 20 })));
    await assertFails(create(t1, "n1", official("n1", { ayahFrom: 0 })));
    await assertFails(create(t1, "n1", without("n1", ["ayahFrom", "ayahTo"], { surahNumber: 115 })));
    await assertFails(create(t1, "n1", without("n1", ["ayahFrom", "ayahTo"], { surahNumber: "2" })));
  });

  test("a two-file recording may leave them out too", async () => {
    const stems = {
      source: "stems",
      stemPaths: { student: "recordings/s1/n1.student.wav", sheikh: "recordings/s1/n1.sheikh.mp3" },
    };
    await assertSucceeds(
      create(as(env, "t1", "teacher"), "n1", without("n1", ["surahNumber", "ayahFrom", "ayahTo"], stems)),
    );
  });

  test("a practice still says what it is: all three required", async () => {
    const s1 = as(env, "s1", "student");
    const bare = practice("n1");
    for (const keys of [["surahNumber", "ayahFrom", "ayahTo"], ["ayahFrom", "ayahTo"], ["ayahTo"]]) {
      const data = { ...bare };
      for (const key of keys) delete data[key];
      await assertFails(create(s1, "n1", data));
    }
    await assertFails(create(s1, "n1", practice("n1", { ayahFrom: null, ayahTo: null })));
    await assertSucceeds(create(s1, "n1", bare));
  });

  test("the teacher and the admin fill, change or clear them later", async () => {
    const t1 = as(env, "t1", "teacher");
    await assertSucceeds(updateDoc(doc(t1, "recordings/r-s1"), { surahNumber: 3, ayahFrom: 5, ayahTo: 9 }));
    await assertSucceeds(updateDoc(doc(t1, "recordings/r-s1"), { ayahFrom: null, ayahTo: null }));
    await assertSucceeds(updateDoc(doc(t1, "recordings/r-s1"), { surahNumber: deleteField() }));
    await assertSucceeds(updateDoc(doc(t1, "recordings/r-s1"), { surahNumber: 112, ayahFrom: 1, ayahTo: 4 }));
    const admin = as(env, "admin", "admin");
    await assertSucceeds(
      updateDoc(doc(admin, "recordings/r-s3"), {
        surahNumber: deleteField(),
        ayahFrom: deleteField(),
        ayahTo: deleteField(),
      }),
    );
    await assertSucceeds(updateDoc(doc(admin, "recordings/r-s3"), { surahNumber: 1 }));
  });

  test("an edit keeps the same combinations", async () => {
    const t1 = as(env, "t1", "teacher");
    await assertFails(updateDoc(doc(t1, "recordings/r-s1"), { surahNumber: null }));
    await assertFails(updateDoc(doc(t1, "recordings/r-s1"), { ayahTo: null }));
    await assertFails(updateDoc(doc(t1, "recordings/r-s1"), { ayahFrom: 30 }));
    await assertFails(updateDoc(doc(t1, "recordings/r-s1"), { surahNumber: 0 }));
    await assertFails(updateDoc(doc(t1, "recordings/r-s1"), { surahNumber: 3, storagePath: "recordings/s1/x.mp3" }));
  });

  test("not another teacher, not the student, not a practice", async () => {
    await assertFails(updateDoc(doc(as(env, "t2", "teacher"), "recordings/r-s1"), { surahNumber: 3 }));
    await assertFails(updateDoc(doc(as(env, "s1", "student"), "recordings/r-s1"), { surahNumber: 3 }));
    await assertFails(updateDoc(doc(as(env, "t1", "student"), "recordings/r-s1"), { surahNumber: 3 }));
    await assertFails(updateDoc(doc(as(env, "s1", "student"), "recordings/p-s1"), { surahNumber: 3 }));
    await assertFails(updateDoc(doc(as(env, "admin", "admin"), "recordings/p-s1"), { surahNumber: 3 }));
  });

  test("a recording without them reads and lists like any other", async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore() as unknown as Firestore;
      await setDoc(
        doc(db, "recordings/bare"),
        without("bare", ["surahNumber", "ayahFrom", "ayahTo"], { createdAt: Timestamp.now() }),
      );
    });
    await assertSucceeds(getDoc(doc(as(env, "s1", "student"), "recordings/bare")));
    await assertSucceeds(getDoc(doc(as(env, "t1", "teacher"), "recordings/bare")));
    const list = query(
      collection(as(env, "t1", "teacher"), "recordings"),
      where("studentId", "==", "s1"),
      where("teacherId", "==", "t1"),
      orderBy("recordedAt", "desc"),
    );
    const snapshot = await assertSucceeds(getDocs(list));
    expect(snapshot.docs.map((d) => d.id)).toContain("bare");
  });
});

describe("two-file recordings (source stems, Task 11)", () => {
  /** An official two-file recording as the upload page sends it. */
  function stems(id: string, over: Record<string, unknown> = {}) {
    return official(id, {
      source: "stems",
      stemPaths: {
        student: `recordings/s1/${id}.student.wav`,
        sheikh: `recordings/s1/${id}.sheikh.mp3`,
      },
      ...over,
    });
  }

  test("the teacher and the admin create one; the joined file is {id}.mp3", async () => {
    await assertSucceeds(create(as(env, "t1", "teacher"), "n1", stems("n1")));
    await assertSucceeds(
      create(as(env, "admin", "admin"), "n2", stems("n2", { uploadedBy: "admin" })),
    );
    // Any accepted extension for each stem.
    await assertSucceeds(
      create(
        as(env, "t1", "teacher"),
        "n3",
        stems("n3", {
          stemPaths: { student: "recordings/s1/n3.student.m4a", sheikh: "recordings/s1/n3.sheikh.webm" },
        }),
      ),
    );
  });

  test("source stereo, written or missing, is the one-file recording as before", async () => {
    const t1 = as(env, "t1", "teacher");
    await assertSucceeds(create(t1, "n1", official("n1", { source: "stereo" })));
    await assertSucceeds(create(t1, "n2", official("n2")));
    await assertFails(create(t1, "n3", official("n3", { source: "mono" })));
    await assertFails(create(t1, "n4", official("n4", { source: null })));
  });

  test("a stereo recording has no stemPaths", async () => {
    const t1 = as(env, "t1", "teacher");
    const stemPaths = { student: "recordings/s1/n1.student.wav", sheikh: "recordings/s1/n1.sheikh.mp3" };
    await assertFails(create(t1, "n1", official("n1", { stemPaths })));
    await assertFails(create(t1, "n1", official("n1", { source: "stereo", stemPaths })));
  });

  test("only official: a student cannot send a practice as stems", async () => {
    const db = as(env, "s1", "student");
    await assertFails(
      create(
        db,
        "n1",
        practice("n1", {
          source: "stems",
          storagePath: "recordings/s1/n1.mp3",
          stemPaths: { student: "recordings/s1/n1.student.m4a", sheikh: "recordings/s1/n1.sheikh.m4a" },
        }),
      ),
    );
    await assertFails(create(db, "n1", stems("n1", { uploadedBy: "s1" })));
  });

  test("the joined file must be {id}.mp3", async () => {
    const t1 = as(env, "t1", "teacher");
    await assertFails(create(t1, "n1", stems("n1", { storagePath: "recordings/s1/n1.wav" })));
    await assertFails(create(t1, "n1", stems("n1", { storagePath: "recordings/s1/n1.student.wav" })));
  });

  test("stemPaths: exactly student and sheikh, this recording's, accepted extensions", async () => {
    const t1 = as(env, "t1", "teacher");
    const withPaths = (stemPaths: unknown) => create(t1, "n1", stems("n1", { stemPaths }));
    const student = "recordings/s1/n1.student.wav";
    const sheikh = "recordings/s1/n1.sheikh.mp3";
    const { stemPaths: _drop, ...missing } = stems("n1");
    await assertFails(create(t1, "n1", missing));
    await assertFails(withPaths("recordings/s1/n1.student.wav"));
    await assertFails(withPaths({ student }));
    await assertFails(withPaths({ student, sheikh, extra: sheikh }));
    await assertFails(withPaths({ student: sheikh, sheikh: student })); // roles swapped
    await assertFails(withPaths({ student: "recordings/s1/n2.student.wav", sheikh }));
    await assertFails(withPaths({ student: "recordings/s2/n1.student.wav", sheikh }));
    await assertFails(withPaths({ student: "recordings/s1/n1.student.exe", sheikh }));
    await assertFails(withPaths({ student: "recordings/s1/n1.wav", sheikh }));
    await assertFails(withPaths({ student, sheikh: "recordings/s1/n1.play.mp3" }));
  });

  test("source and stemPaths never change after the create", async () => {
    for (const [uid, role] of [["t1", "teacher"], ["admin", "admin"]] as const) {
      const ref = doc(as(env, uid, role), "recordings/st-s1");
      await assertFails(updateDoc(ref, { source: "stereo" }));
      await assertFails(
        updateDoc(ref, { stemPaths: { student: "recordings/s1/st-s1.student.mp3", sheikh: "recordings/s1/st-s1.sheikh.mp3" } }),
      );
      await assertFails(updateDoc(ref, { storagePath: "recordings/s1/st-s1.wav" }));
      await assertFails(updateDoc(doc(as(env, uid, role), "recordings/r-s1"), { source: "stems" }));
    }
  });

  test("analysis stays the server's", async () => {
    await assertFails(
      create(as(env, "t1", "teacher"), "n1", stems("n1", { analysis: { status: "merging" } })),
    );
    await assertFails(
      updateDoc(doc(as(env, "t1", "teacher"), "recordings/st-s1"), {
        analysis: { status: "done", segmentCount: 1, swapped: true },
      }),
    );
  });

  test("read, review and delete as any other recording", async () => {
    await assertSucceeds(getDoc(doc(as(env, "s1", "student"), "recordings/st-s1")));
    await assertFails(getDoc(doc(as(env, "s2", "student"), "recordings/st-s1")));
    await assertSucceeds(updateDoc(doc(as(env, "t1", "teacher"), "recordings/st-s1"), { reviewed: false }));
    await assertFails(deleteDoc(doc(as(env, "s1", "student"), "recordings/st-s1")));
    await assertSucceeds(deleteDoc(doc(as(env, "t1", "teacher"), "recordings/st-s1")));
  });
});

describe("server-only fields: analysis and playbackPath", () => {
  const analysis = { status: "done", segmentCount: 2 };
  const playbackPath = "recordings/s1/n1.play.mp3";

  test("no client creates a recording with them, the admin included", async () => {
    await assertFails(create(as(env, "t1", "teacher"), "n1", official("n1", { analysis })));
    await assertFails(create(as(env, "t1", "teacher"), "n1", official("n1", { playbackPath })));
    await assertFails(
      create(as(env, "admin", "admin"), "n1", official("n1", { uploadedBy: "admin", analysis })),
    );
  });

  test("no client changes them later", async () => {
    for (const [uid, role] of [["t1", "teacher"], ["admin", "admin"], ["s1", "student"]] as const) {
      const ref = doc(as(env, uid, role), "recordings/r-s1");
      await assertFails(updateDoc(ref, { analysis }));
      await assertFails(updateDoc(ref, { playbackPath: "recordings/s1/r-s1.play.mp3" }));
      await assertFails(updateDoc(ref, { durationSec: 12 }));
    }
  });
});

describe("demoted teacher (t1 whose role claim is now student)", () => {
  test("loses read, review and delete on t1's recordings", async () => {
    const db = as(env, "t1", "student");
    await assertFails(getDoc(doc(db, "recordings/r-s1")));
    await assertFails(
      getDocs(
        query(
          collection(db, "recordings"),
          where("teacherId", "==", "t1"),
          where("type", "==", "practice"),
          where("reviewed", "==", false),
          orderBy("createdAt"),
        ),
      ),
    );
    await assertFails(updateDoc(doc(db, "recordings/p-s1"), { reviewed: true }));
    await assertFails(deleteDoc(doc(db, "recordings/r-s2")));
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
