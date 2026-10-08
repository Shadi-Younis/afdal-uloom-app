// Shared test environment and fixture data for the Firestore rules tests.
//
// Fixture: admin; teachers t1 (owns h1) and t2 (owns h2); students s1, s2
// in h1 and s3 in h2; one official recording per student, one unreviewed
// practice recording of s1 (with unread feedback), and one note on r-s1.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import {
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, setDoc, Timestamp, type Firestore } from "firebase/firestore";

const rulesPath = fileURLToPath(new URL("../../firestore.rules", import.meta.url));

export async function createTestEnv(): Promise<RulesTestEnvironment> {
  return initializeTestEnvironment({
    // `firebase emulators:exec` sets GCLOUD_PROJECT; it only names the
    // emulator's namespace, nothing reaches the real project.
    projectId: process.env.GCLOUD_PROJECT ?? "afdal-al-uloom",
    firestore: { rules: readFileSync(rulesPath, "utf8") },
  });
}

export type Role = "admin" | "teacher" | "student";

/** A Firestore client signed in as [uid] with the [role] custom claim. */
export function as(env: RulesTestEnvironment, uid: string, role: Role): Firestore {
  return env.authenticatedContext(uid, { role }).firestore() as unknown as Firestore;
}

export function anonymous(env: RulesTestEnvironment): Firestore {
  return env.unauthenticatedContext().firestore() as unknown as Firestore;
}

const created = Timestamp.fromDate(new Date("2026-09-01T08:00:00Z"));

function user(username: string, fullName: string, role: Role, halaqaId: string | null = null) {
  return {
    username,
    fullName,
    role,
    studentCode: role === "student" ? username.toUpperCase() : null,
    halaqaId,
    fcmTokens: [],
    createdAt: created,
  };
}

export function recordingDoc(
  id: string,
  over: Record<string, unknown> = {},
): Record<string, unknown> {
  const studentId = (over.studentId as string) ?? "s1";
  return {
    studentId,
    halaqaId: "h1",
    teacherId: "t1",
    uploadedBy: "t1",
    type: "official",
    surahNumber: 2,
    ayahFrom: 1,
    ayahTo: 20,
    storagePath: `recordings/${studentId}/${id}.mp3`,
    durationSec: 300,
    recordedAt: created,
    createdAt: created,
    unreadFeedback: false,
    reviewed: true,
    ...over,
  };
}

export async function seedFixtures(env: RulesTestEnvironment): Promise<void> {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore() as unknown as Firestore;
    const writes: Array<[string, Record<string, unknown>]> = [
      ["users/admin", user("shadi", "شادي", "admin")],
      ["users/t1", user("t01", "المعلم الأول", "teacher")],
      ["users/t2", user("t02", "المعلم الثاني", "teacher")],
      ["users/s1", user("s001", "أحمد", "student", "h1")],
      ["users/s2", user("s002", "بلال", "student", "h1")],
      ["users/s3", user("s003", "خالد", "student", "h2")],
      ["halaqat/h1", { name: "حلقة الفجر", teacherId: "t1" }],
      ["halaqat/h2", { name: "حلقة العصر", teacherId: "t2" }],
      ["recordings/r-s1", recordingDoc("r-s1", { unreadFeedback: true })],
      ["recordings/r-s2", recordingDoc("r-s2", { studentId: "s2" })],
      [
        "recordings/r-s3",
        recordingDoc("r-s3", { studentId: "s3", halaqaId: "h2", teacherId: "t2", uploadedBy: "t2" }),
      ],
      [
        "recordings/p-s1",
        recordingDoc("p-s1", {
          type: "practice",
          uploadedBy: "s1",
          reviewed: false,
          storagePath: "recordings/s1/p-s1.m4a",
        }),
      ],
      [
        "recordings/r-s1/feedback/f1",
        { teacherId: "t1", note: "أحسنت", atSecond: 12, rating: 5, createdAt: created },
      ],
    ];
    for (const [path, data] of writes) {
      await setDoc(doc(db, path), data);
    }
  });
}
