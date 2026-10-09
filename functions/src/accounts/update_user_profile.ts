import {logger} from "firebase-functions";

import {auth, db} from "../lib/admin.js";
import {requireRole} from "../lib/auth_checks.js";
import {callable} from "../lib/callable.js";
import {F, USERS, emailFor} from "../lib/constants.js";
import {alreadyExists, invalidArgument, permissionDenied} from "../lib/errors.js";
import {getUserDoc, teacherOwnsStudent} from "../lib/lookups.js";
import {asObject, readFullName, readId, readStudentCode, readUsername} from "../lib/validation.js";

/**
 * updateUserProfile({uid, fullName?, username?, studentCode?}) -> null
 *
 * Admin: any user, themselves included; never the role (not a parameter).
 * Teacher: only the fullName of a student in a halaqa they own.
 * At least one field is required. fullName 2..60; username follows the
 * createUser rules and stays unique (`already-exists`, field `username`):
 * it changes the sign-in email AND users/{uid}.username; studentCode only
 * for students, unique (`already-exists`, field `studentCode`).
 */
export const updateUserProfile = callable(async (request) => {
  const caller = requireRole(request, "admin", "teacher");
  const data = asObject(request.data);
  const uid = readId(data, "uid");
  const fullName = data.fullName === undefined ? undefined : readFullName(data);
  const username = data.username === undefined ? undefined : readUsername(data);
  const studentCode = data.studentCode === undefined ? undefined : readStudentCode(data);
  if (fullName === undefined && username === undefined && studentCode === undefined) {
    throw invalidArgument("Nothing to update.");
  }

  if (caller.role === "teacher") {
    if (username !== undefined || studentCode !== undefined) {
      throw permissionDenied("Teachers can only change a student's name.");
    }
    if (!(await teacherOwnsStudent(caller.uid, uid))) {
      throw permissionDenied("Teachers can only edit their own students.");
    }
  }

  const target = await getUserDoc(uid);
  if (studentCode !== undefined) {
    if (target[F.role] !== "student") throw invalidArgument("Only students have a studentCode.");
    if (await studentCodeTakenByOther(studentCode, uid)) {
      throw alreadyExists("studentCode already exists.", "studentCode");
    }
  }

  // Auth first: its unique email is what makes the username unique, and it
  // refuses a taken one before anything is changed.
  const before = await auth.getUser(uid);
  const authChanges = {
    ...(fullName !== undefined && {displayName: fullName}),
    ...(username !== undefined && {email: emailFor(username)}),
  };
  if (Object.keys(authChanges).length > 0) await auth.updateUser(uid, authChanges);

  try {
    await db.runTransaction(async (transaction) => {
      // Checked again inside the transaction, as in createUser.
      if (studentCode !== undefined) {
        const sameCode = await transaction.get(
          db.collection(USERS).where(F.studentCode, "==", studentCode).limit(2),
        );
        if (sameCode.docs.some((doc) => doc.id !== uid)) {
          throw alreadyExists("studentCode already exists.", "studentCode");
        }
      }
      transaction.update(db.collection(USERS).doc(uid), {
        ...(fullName !== undefined && {[F.fullName]: fullName}),
        ...(username !== undefined && {[F.username]: username}),
        ...(studentCode !== undefined && {[F.studentCode]: studentCode}),
      });
    });
  } catch (error) {
    // Put the sign-in email back, so it never disagrees with the users doc.
    if (Object.keys(authChanges).length > 0) {
      await auth
        .updateUser(uid, {email: before.email, displayName: before.displayName ?? null})
        .catch((undoError) => logger.error(`updateUserProfile: could not undo ${uid}`, undoError));
    }
    throw error;
  }
  return null;
});

async function studentCodeTakenByOther(studentCode: string, uid: string): Promise<boolean> {
  const snapshot = await db.collection(USERS).where(F.studentCode, "==", studentCode).limit(2).get();
  return snapshot.docs.some((doc) => doc.id !== uid);
}
