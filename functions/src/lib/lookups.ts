import {DocumentData} from "firebase-admin/firestore";

import {db} from "./admin.js";
import {HALAQAT, USERS} from "./constants.js";
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
