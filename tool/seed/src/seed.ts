// Fills the Auth and Firestore EMULATORS with test data (see data.ts).
// Run it through tool/seed_emulator.ps1 while tool/emulators.ps1 is running.
// Safe to run again: every account and document has a fixed id.

// Refuse before touching firebase-admin: without these variables the Admin
// SDK would talk to the real project.
const required = ["FIRESTORE_EMULATOR_HOST", "FIREBASE_AUTH_EMULATOR_HOST"] as const;
const missing = required.filter((name) => !process.env[name]);
if (missing.length > 0) {
  console.error(
    `Refusing to seed: ${missing.join(" and ")} not set. ` +
      "This script only writes to the Firebase emulators.",
  );
  process.exit(1);
}

// A host on another machine could be a tunnel to anything; only accept this
// machine's emulators.
const localHosts = ["localhost", "127.0.0.1", "0.0.0.0"];
const remote = required.filter((name) => {
  const host = process.env[name]!.replace(/:\d+$/, "");
  return !localHosts.includes(host);
});
if (remote.length > 0) {
  console.error(
    `Refusing to seed: ${remote.map((name) => `${name}=${process.env[name]}`).join(", ")}. ` +
      `Hosts must be ${localHosts.join(", ")}.`,
  );
  process.exit(1);
}

const { initializeApp } = await import("firebase-admin/app");
const { getAuth } = await import("firebase-admin/auth");
const { getFirestore, Timestamp } = await import("firebase-admin/firestore");
const data = await import("./data.js");

const projectId = process.env.GCLOUD_PROJECT ?? "afdal-al-uloom";
initializeApp({ projectId });
const auth = getAuth();
const db = getFirestore();

const usersCreatedAt = Timestamp.fromDate(new Date("2026-08-25T09:00:00Z"));
const hour = 60 * 60 * 1000;

async function seedAccounts(): Promise<void> {
  for (const user of data.users) {
    const props = {
      email: `${user.uid}@${data.emailDomain}`,
      password: data.devPassword,
      displayName: user.fullName,
    };
    try {
      await auth.updateUser(user.uid, props);
    } catch (error) {
      if ((error as { code?: string }).code !== "auth/user-not-found") throw error;
      await auth.createUser({ uid: user.uid, ...props });
    }
    await auth.setCustomUserClaims(user.uid, { role: user.role });
  }
}

async function seedFirestore(): Promise<void> {
  const batch = db.batch();

  for (const user of data.users) {
    const isStudent = user.role === "student";
    batch.set(db.doc(`users/${user.uid}`), {
      username: user.uid,
      fullName: user.fullName,
      role: user.role,
      studentCode: isStudent ? user.uid.toUpperCase() : null,
      halaqaId: isStudent ? user.halaqaId : null,
      fcmTokens: [],
      createdAt: usersCreatedAt,
      disabled: false,
    });
  }

  for (const halaqa of data.halaqat) {
    batch.set(db.doc(`halaqat/${halaqa.id}`), {
      name: halaqa.name,
      teacherId: halaqa.teacherId,
    });
  }

  const studentHalaqa = new Map(data.users.map((u) => [u.uid, u.halaqaId]));
  const halaqaTeacher = new Map(data.halaqat.map((h) => [h.id, h.teacherId]));

  for (const r of data.recordings) {
    const halaqaId = studentHalaqa.get(r.studentId)!;
    const teacherId = halaqaTeacher.get(halaqaId)!;
    const official = r.type === "official";
    const recordedAt = new Date(r.recordedAt);
    batch.set(db.doc(`recordings/${r.id}`), {
      studentId: r.studentId,
      halaqaId,
      teacherId,
      uploadedBy: official ? teacherId : r.studentId,
      type: r.type,
      surahNumber: r.surahNumber,
      ayahFrom: r.ayahFrom,
      ayahTo: r.ayahTo,
      // No audio files yet; the path is what the upload will use.
      storagePath: `recordings/${r.studentId}/${r.id}.${official ? "mp3" : "m4a"}`,
      durationSec: (r.ayahTo - r.ayahFrom + 1) * 20,
      recordedAt: Timestamp.fromDate(recordedAt),
      // Studio files are uploaded a couple of hours after the session.
      createdAt: Timestamp.fromDate(new Date(recordedAt.getTime() + (official ? 2 * hour : 0))),
      unreadFeedback: r.unreadFeedback,
      reviewed: r.reviewed,
    });
  }

  const recordingById = new Map(data.recordings.map((r) => [r.id, r]));
  data.notes.forEach((n, i) => {
    const recording = recordingById.get(n.recordingId)!;
    const teacherId = halaqaTeacher.get(studentHalaqa.get(recording.studentId)!)!;
    const createdAt = new Date(new Date(recording.recordedAt).getTime() + (24 + i) * hour);
    batch.set(db.doc(`recordings/${n.recordingId}/feedback/${n.id}`), {
      teacherId,
      note: n.note,
      atSecond: n.atSecond ?? null,
      rating: n.rating ?? null,
      createdAt: Timestamp.fromDate(createdAt),
    });
  });

  await batch.commit();
}

await seedAccounts();
await seedFirestore();

const count = (role: string) => data.users.filter((u) => u.role === role).length;
console.log(
  `Seeded project ${projectId}: ${data.users.length} accounts ` +
    `(${count("admin")} admin, ${count("teacher")} teachers, ${count("student")} students), ` +
    `${data.halaqat.length} halaqat, ${data.recordings.length} recordings, ` +
    `${data.notes.length} feedback notes. Password for every account: ${data.devPassword}`,
);
