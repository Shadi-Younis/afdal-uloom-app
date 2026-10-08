import {FieldValue} from "firebase-admin/firestore";
import {logger} from "firebase-functions";

import {auth, db} from "../lib/admin.js";
import {requireRole} from "../lib/auth_checks.js";
import {callable} from "../lib/callable.js";
import {F, USERS, emailFor} from "../lib/constants.js";
import {alreadyExists, invalidArgument, permissionDenied} from "../lib/errors.js";
import {getHalaqa} from "../lib/lookups.js";
import {
  asObject,
  readFullName,
  readOptionalId,
  readPassword,
  readRole,
  readStudentCode,
  readUsername,
} from "../lib/validation.js";

/**
 * createUser({username, password, fullName, role, halaqaId?, studentCode?})
 * -> {uid}
 *
 * Admin: any role. Teacher: only students, only into a halaqa they own.
 * Students need an existing halaqaId and a unique studentCode; admins and
 * teachers must have neither.
 */
export const createUser = callable(async (request) => {
  const caller = requireRole(request, "admin", "teacher");
  const data = asObject(request.data);
  const username = readUsername(data);
  const password = readPassword(data, "password");
  const fullName = readFullName(data);
  const role = readRole(data);
  const halaqaId = readOptionalId(data, "halaqaId");
  const studentCode = readStudentCode(data);

  if (caller.role === "teacher" && role !== "student") {
    throw permissionDenied("Teachers can only create students.");
  }

  if (role === "student") {
    if (!halaqaId) throw invalidArgument("halaqaId is required for a student.");
    if (!studentCode) throw invalidArgument("studentCode is required for a student.");
    const halaqa = await getHalaqa(halaqaId);
    if (caller.role === "teacher" && halaqa[F.teacherId] !== caller.uid) {
      throw permissionDenied("Teachers can only add students to their own halaqa.");
    }
    if (await studentCodeTaken(studentCode)) {
      throw alreadyExists("studentCode already exists.", "studentCode");
    }
  } else if (halaqaId !== undefined || studentCode !== undefined) {
    throw invalidArgument("Only students have a halaqaId and a studentCode.");
  }

  // Auth's unique email is what makes usernames unique.
  const {uid} = await auth.createUser({
    email: emailFor(username),
    password,
    displayName: fullName,
  });

  // From here on, any failure deletes the Auth user: no half-created accounts.
  try {
    await auth.setCustomUserClaims(uid, {role});
    await db.runTransaction(async (transaction) => {
      // Checked again inside the transaction to close the race between two
      // admins creating the same studentCode at once.
      if (studentCode) {
        const sameCode = await transaction.get(
          db.collection(USERS).where(F.studentCode, "==", studentCode).limit(1),
        );
        if (!sameCode.empty) {
          throw alreadyExists("studentCode already exists.", "studentCode");
        }
      }
      transaction.create(db.collection(USERS).doc(uid), {
        [F.username]: username,
        [F.fullName]: fullName,
        [F.role]: role,
        [F.studentCode]: studentCode ?? null,
        [F.halaqaId]: halaqaId ?? null,
        [F.fcmTokens]: [],
        [F.createdAt]: FieldValue.serverTimestamp(),
      });
    });
  } catch (error) {
    await auth.deleteUser(uid).catch((cleanupError) =>
      logger.error(`createUser: could not delete half-created user ${uid}`, cleanupError),
    );
    throw error;
  }

  return {uid};
});

async function studentCodeTaken(studentCode: string): Promise<boolean> {
  const snapshot = await db
    .collection(USERS)
    .where(F.studentCode, "==", studentCode)
    .limit(1)
    .get();
  return !snapshot.empty;
}
