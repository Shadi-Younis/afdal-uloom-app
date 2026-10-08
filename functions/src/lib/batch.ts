import {DocumentReference, UpdateData} from "firebase-admin/firestore";

import {db} from "./admin.js";
import {BATCH_LIMIT} from "./constants.js";

export interface Update {
  ref: DocumentReference;
  data: UpdateData<Record<string, unknown>>;
}

/**
 * Applies [updates] in batches of at most 500 writes, in order. Each batch is
 * atomic; the whole list is not, so callers put the most important write
 * first and keep the updates idempotent (re-running fixes a partial run).
 */
export async function updateInBatches(updates: Update[]): Promise<void> {
  for (let start = 0; start < updates.length; start += BATCH_LIMIT) {
    const batch = db.batch();
    for (const {ref, data} of updates.slice(start, start + BATCH_LIMIT)) {
      batch.update(ref, data);
    }
    await batch.commit();
  }
}
