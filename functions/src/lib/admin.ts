import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";

// One Admin app for every function in this codebase. In the emulator the
// SDK picks up the *_EMULATOR_HOST variables set by the Functions emulator.
if (getApps().length === 0) initializeApp();

export const auth = getAuth();
export const db = getFirestore();
