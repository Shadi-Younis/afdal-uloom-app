// Shared setup for the functions tests: emulator endpoints, a fresh fixture
// per test, ID tokens of fixture users and HTTP calls to the callables.
//
// Fixture: admin; teachers t1 (owns h1) and t2 (owns h2); students s1, s2
// in h1 (studentCode S001, S002) and s3 in h2 (S003); recordings r1, r2 of
// s1 and r3 of s2 (all h1 / t1) and r4 of s3 (h2 / t2). Every password is
// "password1".
import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore, Timestamp} from "firebase-admin/firestore";

const required = ["FIRESTORE_EMULATOR_HOST", "FIREBASE_AUTH_EMULATOR_HOST"];
for (const name of required) {
  if (!process.env[name]) {
    throw new Error(`${name} is not set: run these tests through tool/test_functions.ps1.`);
  }
}

export const projectId = process.env.GCLOUD_PROJECT ?? "afdal-al-uloom";
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST!;
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST!;
const functionsHost = process.env.FUNCTIONS_EMULATOR_HOST ?? "127.0.0.1:5001";

if (getApps().length === 0) initializeApp({projectId});
export const auth = getAuth();
export const db = getFirestore();

export const PASSWORD = "password1";
export const emailFor = (username: string) => `${username}@afdal-uloom.app`;

type Role = "admin" | "teacher" | "student";

async function addUser(uid: string, role: Role, halaqaId: string | null = null) {
  const studentCode = role === "student" ? `S00${uid.slice(1)}` : null;
  await auth.createUser({uid, email: emailFor(uid), password: PASSWORD});
  await auth.setCustomUserClaims(uid, {role});
  await db.doc(`users/${uid}`).set({
    username: uid,
    fullName: `name ${uid}`,
    role,
    studentCode,
    halaqaId,
    fcmTokens: [],
    createdAt: Timestamp.now(),
  });
}

function recording(id: string, studentId: string, halaqaId: string, teacherId: string) {
  return db.doc(`recordings/${id}`).set({
    studentId,
    halaqaId,
    teacherId,
    uploadedBy: teacherId,
    type: "official",
    surahNumber: 1,
    ayahFrom: 1,
    ayahTo: 7,
    storagePath: `recordings/${studentId}/${id}.mp3`,
    durationSec: null,
    recordedAt: Timestamp.now(),
    createdAt: Timestamp.now(),
    unreadFeedback: false,
    reviewed: true,
  });
}

/** Empties both emulators and writes the fixture. */
export async function resetFixture(): Promise<void> {
  await Promise.all([
    fetch(`http://${firestoreHost}/emulator/v1/projects/${projectId}/databases/(default)/documents`, {
      method: "DELETE",
    }),
    fetch(`http://${authHost}/emulator/v1/projects/${projectId}/accounts`, {method: "DELETE"}),
  ]);
  await addUser("admin", "admin");
  await addUser("t1", "teacher");
  await addUser("t2", "teacher");
  await db.doc("halaqat/h1").set({name: "h1", teacherId: "t1"});
  await db.doc("halaqat/h2").set({name: "h2", teacherId: "t2"});
  await addUser("s1", "student", "h1");
  await addUser("s2", "student", "h1");
  await addUser("s3", "student", "h2");
  await recording("r1", "s1", "h1", "t1");
  await recording("r2", "s1", "h1", "t1");
  await recording("r3", "s2", "h1", "t1");
  await recording("r4", "s3", "h2", "t2");
}

/** Signs in through the Auth emulator; resolves to the ID token or rejects with the Auth error code. */
export async function signIn(email: string, password: string): Promise<string> {
  const response = await fetch(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake`,
    {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({email, password, returnSecureToken: true}),
    },
  );
  const body = (await response.json()) as {idToken?: string; error?: {message: string}};
  if (!body.idToken) throw new Error(body.error?.message ?? "sign-in failed");
  return body.idToken;
}

export const tokenOf = (uid: string) => signIn(emailFor(uid), PASSWORD);

export type CallResult =
  | {ok: true; data: unknown}
  | {ok: false; code: string; message: string; details?: unknown};

/** Calls a callable over HTTP, exactly as the app does. */
export async function call(name: string, data: unknown, idToken?: string): Promise<CallResult> {
  const response = await fetch(`http://${functionsHost}/${projectId}/me-west1/${name}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(idToken ? {Authorization: `Bearer ${idToken}`} : {}),
    },
    body: JSON.stringify({data}),
  });
  const body = (await response.json()) as {
    result?: unknown;
    error?: {status: string; message: string; details?: unknown};
  };
  if (body.error) {
    return {
      ok: false,
      // INVALID_ARGUMENT -> invalid-argument, as the client SDKs report it.
      code: body.error.status.toLowerCase().replace(/_/g, "-"),
      message: body.error.message,
      details: body.error.details,
    };
  }
  return {ok: true, data: body.result};
}

/** Calls as the fixture user [uid]. */
export async function callAs(uid: string, name: string, data: unknown): Promise<CallResult> {
  return call(name, data, await tokenOf(uid));
}
