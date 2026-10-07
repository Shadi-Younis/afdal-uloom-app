import {setGlobalOptions} from "firebase-functions/v2";
import {onCall} from "firebase-functions/v2/https";

// Every function runs next to Firestore and Storage in Tel Aviv. The app uses
// the same region through kFunctionsRegion in lib/app/firebase_setup.dart.
setGlobalOptions({region: "me-west1", maxInstances: 10});

// TODO: remove once real functions exist; only proves the app <-> Functions wiring.
export const ping = onCall((request) => {
  return {ok: true, uid: request.auth?.uid ?? null};
});
