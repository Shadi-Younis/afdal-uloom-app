import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";

import {STORAGE_BUCKET} from "./constants.js";

// One Admin app for every function in this codebase. In the emulator the
// SDK picks up the *_EMULATOR_HOST variables set by the Functions emulator.
if (getApps().length === 0) initializeApp();

export const auth = getAuth();
export const db = getFirestore();
export const bucket = getStorage().bucket(STORAGE_BUCKET);
