// Creates the FIRST admin in the REAL project (afdal-al-uloom). Every later
// account is created from the app through the createUser function.
// Steps, in Arabic: docs/BOOTSTRAP_ADMIN.md.
//
//   npm --prefix tool/bootstrap_admin run bootstrap -- <path-to-key.json> --confirm afdal-al-uloom
//
// With --reset-password <username> it instead sets a new password for an
// EXISTING admin who forgot theirs (and nobody else can reset it: another
// admin may not, see functions/src/accounts/reset_password.ts):
//
//   npm --prefix tool/bootstrap_admin run bootstrap -- <path-to-key.json> --confirm afdal-al-uloom --reset-password <username>
//
// Username, full name and password are asked interactively, so the password
// is never echoed and never lands in the shell history.
import {readFileSync} from "node:fs";
import {createInterface} from "node:readline/promises";

const PROJECT_ID = "afdal-al-uloom";
// Same rules as functions/src/lib/constants.ts; change both together.
const EMAIL_DOMAIN = "afdal-uloom.app";
const USERNAME_PATTERN = /^[a-z0-9._-]{3,20}$/;
const PASSWORD_LENGTH = {min: 6, max: 64};
const FULL_NAME_LENGTH = {min: 2, max: 60};

function fail(message: string): never {
  console.error(`\nRefusing: ${message}`);
  process.exit(1);
}

// ---- Guards: all checked before any Firebase code runs. -----------------

const emulatorVars = Object.keys(process.env).filter((name) => name.endsWith("_EMULATOR_HOST"));
if (emulatorVars.length > 0) {
  fail(`${emulatorVars.join(", ")} set. This script is for the real project; use tool/seed for the emulators.`);
}

const args = process.argv.slice(2);
const confirmIndex = args.indexOf("--confirm");
if (confirmIndex === -1 || args[confirmIndex + 1] !== PROJECT_ID) {
  fail(`pass --confirm ${PROJECT_ID} to confirm you mean the real project.`);
}
const resetIndex = args.indexOf("--reset-password");
const resetUsername = resetIndex === -1 ? undefined : args[resetIndex + 1]?.trim().toLowerCase();
if (resetIndex !== -1 && (!resetUsername || !USERNAME_PATTERN.test(resetUsername))) {
  fail("pass the admin's username after --reset-password.");
}
const keyPath = args.find(
  (arg, i) => !arg.startsWith("--") && i !== confirmIndex + 1 && (resetIndex === -1 || i !== resetIndex + 1),
);
if (!keyPath) fail("pass the path to the service account key file.");

let serviceAccount: {project_id?: string; client_email?: string; private_key?: string};
try {
  serviceAccount = JSON.parse(readFileSync(keyPath, "utf8"));
} catch (error) {
  fail(`cannot read the key file ${keyPath}: ${(error as Error).message}`);
}
if (serviceAccount.project_id !== PROJECT_ID) {
  fail(`the key belongs to project ${serviceAccount.project_id}, not ${PROJECT_ID}.`);
}

if (!process.stdin.isTTY) fail("run this in an interactive terminal (the password is typed, not piped).");

// ---- Questions ------------------------------------------------------------

/** Reads a line without echoing it. */
function askHidden(question: string): Promise<string> {
  return new Promise((resolve) => {
    process.stdout.write(question);
    const stdin = process.stdin;
    stdin.setRawMode(true);
    stdin.resume();
    stdin.setEncoding("utf8");
    let value = "";
    const onData = (chunk: string) => {
      for (const char of chunk) {
        if (char === "\r" || char === "\n") {
          stdin.setRawMode(false);
          stdin.pause();
          stdin.off("data", onData);
          process.stdout.write("\n");
          resolve(value);
          return;
        }
        if (char === "\u0003") {
          process.stdout.write("\n");
          process.exit(130); // Ctrl+C
        }
        if (char === "\u007f" || char === "\b") {
          value = value.slice(0, -1);
        } else {
          value += char;
        }
      }
    };
    stdin.on("data", onData);
  });
}

/** Asks for a password twice, hidden; exits unless both match and fit the limits. */
async function askNewPassword(): Promise<string> {
  const password = await askHidden(`Password (${PASSWORD_LENGTH.min}-${PASSWORD_LENGTH.max} characters): `);
  if (password.length < PASSWORD_LENGTH.min || password.length > PASSWORD_LENGTH.max) {
    fail("password length.");
  }
  if ((await askHidden("Repeat the password: ")) !== password) fail("the passwords differ.");
  return password;
}

let username: string;
let fullName = "";
if (resetUsername !== undefined) {
  username = resetUsername;
  console.log(`Resetting the password of admin ${username} in ${PROJECT_ID}.`);
} else {
  const rl = createInterface({input: process.stdin, output: process.stdout});
  username = (await rl.question("Username (3-20 of a-z 0-9 . _ -): ")).trim().toLowerCase();
  if (!USERNAME_PATTERN.test(username)) fail("invalid username.");
  fullName = (await rl.question("Full name (Arabic, 2-60 characters): ")).trim();
  if (fullName.length < FULL_NAME_LENGTH.min || fullName.length > FULL_NAME_LENGTH.max) {
    fail("full name must be 2-60 characters.");
  }
  rl.close();
}

const password = await askNewPassword();

const {cert, initializeApp} = await import("firebase-admin/app");
const {getAuth} = await import("firebase-admin/auth");
const {FieldValue, getFirestore} = await import("firebase-admin/firestore");

initializeApp({credential: cert(keyPath), projectId: PROJECT_ID});
const auth = getAuth();
const db = getFirestore();
const email = `${username}@${EMAIL_DOMAIN}`;

// ---- Reset an admin's password ----------------------------------------

if (resetUsername !== undefined) {
  const user = await auth.getUserByEmail(email).catch((error: {code?: string}) => {
    if (error.code === "auth/user-not-found") fail(`no account with username ${username}.`);
    throw error;
  });
  const profile = await db.doc(`users/${user.uid}`).get();
  // Both must say admin: this mode must never become a way into a teacher's
  // or a student's account.
  if (user.customClaims?.role !== "admin" || profile.get("role") !== "admin") {
    fail(`${username} is not an admin; reset other accounts from the app.`);
  }
  await auth.updateUser(user.uid, {password});
  // As in the app's reset: a lost or shared device must sign in again.
  await auth.revokeRefreshTokens(user.uid);
  console.log(`\nNew password set for admin ${username} (uid ${user.uid}). Other sessions are signed out.`);
  if (user.disabled) {
    console.log("Note: this account is DISABLED; another admin must enable it before it can sign in.");
  }
  process.exit(0);
}

// ---- Create ---------------------------------------------------------------

try {
  await auth.getUserByEmail(email);
  fail(`username ${username} already exists.`);
} catch (error) {
  if ((error as {code?: string}).code !== "auth/user-not-found") throw error;
}

const {uid} = await auth.createUser({email, password, displayName: fullName});
try {
  await auth.setCustomUserClaims(uid, {role: "admin"});
  await db.doc(`users/${uid}`).create({
    username,
    fullName,
    role: "admin",
    studentCode: null,
    halaqaId: null,
    fcmTokens: [],
    createdAt: FieldValue.serverTimestamp(),
    disabled: false,
  });
} catch (error) {
  // No half-created admin: remove the Auth user again.
  await auth.deleteUser(uid);
  throw error;
}

console.log(`\nCreated admin ${username} (uid ${uid}) in ${PROJECT_ID}. Sign in to the app with this username.`);
