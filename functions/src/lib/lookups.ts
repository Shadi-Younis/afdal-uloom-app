import {DocumentData} from "firebase-admin/firestore";

import {db} from "./admin.js";
import {F, HALAQAT, USERS} from "./constants.js";
import {notFound} from "./errors.js";

/** The users doc of [uid]; throws `not-found` when missing. */
export async function getUserDoc(uid: string): Promise<DocumentData> {
  const snapshot = await db.collection(USERS).doc(uid).get();
  if (!snapshot.exists) throw notFound("User not found.");
  return snapshot.data()!;
}

/** The halaqa [halaqaId]; throws `not-found` when missing. */
export async function getHalaqa(halaqaId: string): Promise<DocumentData> {
  const snapshot = await db.collection(HALAQAT).doc(halaqaId).get();
  if (!snapshot.exists) throw notFound("Halaqa not found.");
  return snapshot.data()!;
}

/**
 * Whether [uid] is a student in a halaqa that [teacherId] teaches. False
 * (never an error) for a missing user or halaqa, so a teacher learns
 * nothing about users outside their halaqat.
 */
export async function teacherOwnsStudent(teacherId: string, uid: string): Promise<boolean> {
  try {
    const student = await getUserDoc(uid);
    if (student[F.role] !== "student" || typeof student[F.halaqaId] !== "string") {
      return false;
    }
    const halaqa = await getHalaqa(student[F.halaqaId]);
    return halaqa[F.teacherId] === teacherId;
  } catch {
    return false;
  }
}

/** How many admins other than [exceptUid] are not disabled (their users docs). */
export async function otherActiveAdminCount(exceptUid: string): Promise<number> {
  const admins = await db.collection(USERS).where(F.role, "==", "admin").get();
  return admins.docs.filter((doc) => doc.id !== exceptUid && doc.get(F.disabled) !== true).length;
}
