import {CallableRequest, onCall} from "firebase-functions/v2/https";

import {toHttpsError} from "./errors.js";

/**
 * An onCall function whose unexpected errors reach the client as an
 * HttpsError with a proper code (see toHttpsError), never as a raw error.
 */
export function callable<Result>(
  handler: (request: CallableRequest) => Promise<Result>,
) {
  return onCall(async (request) => {
    try {
      return await handler(request);
    } catch (error) {
      throw toHttpsError(error);
    }
  });
}
