// Fills the Auth, Firestore and Storage EMULATORS with test data (see
// data.ts), including a recitation (al-Minshawi) for every recording, read
// from the folder that tool/seed/download_test_audio.ps1 fills.
// Run it through tool/seed_emulator.ps1 while tool/emulators.ps1 is running.
// Safe to run again: every account and document has a fixed id.

import { existsSync } from "node:fs";

// Refuse before touching firebase-admin: without these variables the Admin
// SDK would talk to the real project.
const required = [
  "FIRESTORE_EMULATOR_HOST",
  "FIREBASE_AUTH_EMULATOR_HOST",
  "FIREBASE_STORAGE_EMULATOR_HOST",
] as const;
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

// Without the recitations every recording would be silent; say how to get them.
const { audioDir, missingClips, loadClipAudio, loadPracticeAudio, loadStemsAudio } = await import("./test_audio.js");
const missingAudio = missingClips();
if (missingAudio.length > 0) {
  const what = existsSync(audioDir)
    ? `${missingAudio.map((c) => c.file).join(", ")} not found in ${audioDir}`
    : `the audio folder ${audioDir} does not exist`;
  console.error(
    `Refusing to seed: ${what}. ` +
      "Download them first: powershell -ExecutionPolicy Bypass -File tool/seed/download_test_audio.ps1",
  );
  process.exit(1);
}

const { initializeApp } = await import("firebase-admin/app");
const { getAuth } = await import("firebase-admin/auth");
const { getFirestore, Timestamp } = await import("firebase-admin/firestore");
const { getStorage } = await import("firebase-admin/storage");
const data = await import("./data.js");
// The same ayah table as the app and the functions.
const { isValidAyahRange } = await import("../../../functions/src/lib/surahs.js");

const badRange = data.recordings.find((r) => !isValidAyahRange(r.surahNumber, r.ayahFrom, r.ayahTo));
if (badRange) {
  console.error(`Refusing to seed: ${badRange.id} has ayat outside surah ${badRange.surahNumber}.`);
  process.exit(1);
}

const clipAudio = await loadClipAudio();
const practiceAudio = await loadPracticeAudio(
  data.recordings.filter((r) => r.type === "practice").map((r) => r.clipId),
);
const stemsAudio = await loadStemsAudio();

/** What a recording's file is: the studio MP3, or the phone's mono .m4a for practice. */
interface RecordingAudio {
  bytes: Buffer;
  durationSec: number;
  extension: "mp3" | "m4a";
  contentType: string;
}

/**
 * A two-file recording's own audio is the joined file the server writes;
 * its length is the stems' (its bytes are not uploaded: see seedAudio).
 */
function audioOf(r: { clipId: string; type: string; source: string }): RecordingAudio {
  if (r.source === "stems") {
    return { bytes: stemsAudio.student, durationSec: stemsAudio.durationSec, extension: "mp3", contentType: "audio/mpeg" };
  }
  if (r.type === "practice") {
    const { m4a, durationSec } = practiceAudio.get(r.clipId)!;
    return { bytes: m4a, durationSec, extension: "m4a", contentType: "audio/mp4" };
  }
  const { mp3, durationSec } = clipAudio.get(r.clipId)!;
  return { bytes: mp3, durationSec, extension: "mp3", contentType: "audio/mpeg" };
}

// A note "at second 40" on a 19-second recitation could never be reached.
const recordingById = new Map(data.recordings.map((r) => [r.id, r]));
const lateNote = data.notes.find(
  (n) => n.atSecond != null && n.atSecond >= audioOf(recordingById.get(n.recordingId)!).durationSec,
);
if (lateNote) {
  console.error(`Refusing to seed: ${lateNote.id} is at second ${lateNote.atSecond}, after the end of its audio.`);
  process.exit(1);
}

const projectId = process.env.GCLOUD_PROJECT ?? "afdal-al-uloom";
initializeApp({ projectId });
const auth = getAuth();
const db = getFirestore();
const bucket = getStorage().bucket(data.storageBucket);
const audioPathOf = (r: { id: string; studentId: string; clipId: string; type: string; source: string }) =>
  `recordings/${r.studentId}/${r.id}.${audioOf(r).extension}`;
/** The two files of a two-file recording (StoragePaths.stem in the app). */
const stemPathsOf = (r: { id: string; studentId: string }) => ({
  student: `recordings/${r.studentId}/${r.id}.student.mp3`,
  sheikh: `recordings/${r.studentId}/${r.id}.sheikh.mp3`,
});
/** How many files go to the Storage emulator at once (each starts a function). */
const uploadsAtOnce = 4;

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

  // teacherName as the app writes it (firestore.rules: the teacher's fullName).
  const fullNameOf = new Map(data.users.map((u) => [u.uid, u.fullName]));
  for (const halaqa of data.halaqat) {
    batch.set(db.doc(`halaqat/${halaqa.id}`), {
      name: halaqa.name,
      teacherId: halaqa.teacherId,
      teacherName: fullNameOf.get(halaqa.teacherId)!,
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
      storagePath: audioPathOf(r),
      durationSec: audioOf(r).durationSec,
      recordedAt: Timestamp.fromDate(recordedAt),
      // Studio files are uploaded a couple of hours after the session.
      createdAt: Timestamp.fromDate(new Date(recordedAt.getTime() + (official ? 2 * hour : 0))),
      unreadFeedback: r.unreadFeedback,
      reviewed: r.reviewed,
      ...(r.source === "stems" ? { source: "stems", stemPaths: stemPathsOf(r) } : {}),
    });
  }

  data.notes.forEach((n, i) => {
    const recording = recordingById.get(n.recordingId)!;
    const teacherId = halaqaTeacher.get(studentHalaqa.get(recording.studentId)!)!;
    const createdAt = new Date(new Date(recording.recordedAt).getTime() + (24 + i) * hour);
    batch.set(db.doc(`recordings/${n.recordingId}/feedback/${n.id}`), {
      teacherId,
      kind: "text",
      note: n.note,
      atSecond: n.atSecond ?? null,
      createdAt: Timestamp.fromDate(createdAt),
    });
  });

  await batch.commit();
}

/**
 * Uploads (or overwrites) every recording's audio file, after deleting what
 * older seeds left in .emulator-data at the same id under another extension
 * (generated .wav tones; practice recordings were .mp3 before Task 10). A
 * two-file recording gets its two stems instead, as the upload page sends
 * them; the emulator's onRecordingUploaded joins them into its storagePath.
 * A few files at a time: each upload of an official file starts a function,
 * and too many at once overload the Functions emulator.
 */
async function seedAudio(): Promise<void> {
  const save = (path: string, bytes: Buffer, contentType: string, token: string) =>
    bucket.file(path).save(bytes, {
      contentType,
      // A fixed token: getDownloadURL() needs one, and seeding again keeps
      // the URLs the app may have cached.
      metadata: { metadata: { firebaseStorageDownloadTokens: token } },
    });
  const seedOne = async (r: (typeof data.recordings)[number]) => {
    const audio = audioOf(r);
    if (r.source === "stems") {
      // The joined file of an earlier seed: the server writes it again.
      for (const old of [audioPathOf(r), `recordings/${r.studentId}/${r.id}.play.mp3`]) {
        await bucket.file(old).delete({ ignoreNotFound: true });
      }
      const stems = stemPathsOf(r);
      await save(stems.student, stemsAudio.student, "audio/mpeg", `seed-${r.id}-student`);
      await save(stems.sheikh, stemsAudio.sheikh, "audio/mpeg", `seed-${r.id}-sheikh`);
      return;
    }
    for (const stale of ["wav", "mp3", "m4a"].filter((ext) => ext !== audio.extension)) {
      await bucket.file(`recordings/${r.studentId}/${r.id}.${stale}`).delete({ ignoreNotFound: true });
    }
    await save(audioPathOf(r), audio.bytes, audio.contentType, `seed-${r.id}`);
  };
  for (let start = 0; start < data.recordings.length; start += uploadsAtOnce) {
    await Promise.all(data.recordings.slice(start, start + uploadsAtOnce).map(seedOne));
  }
}

await seedAccounts();
await seedFirestore();
await seedAudio();

const count = (role: string) => data.users.filter((u) => u.role === role).length;
console.log(
  `Seeded project ${projectId}: ${data.users.length} accounts ` +
    `(${count("admin")} admin, ${count("teacher")} teachers, ${count("student")} students), ` +
    `${data.halaqat.length} halaqat, ${data.recordings.length} recordings, ` +
    `${data.notes.length} feedback notes, ${data.recordings.length + 1} audio files ` +
    `(${clipAudio.size} recitations from ${audioDir}). Password for every account: ${data.devPassword}`,
);
