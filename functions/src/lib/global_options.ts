import {setGlobalOptions} from "firebase-functions/v2";

import {REGION} from "./constants.js";

// Imported first by index.ts: onCall() reads the global options when each
// function is defined, so they must be set before any function module loads.
setGlobalOptions({region: REGION, maxInstances: 10});
