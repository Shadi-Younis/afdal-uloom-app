import {Timestamp} from "firebase-admin/firestore";
import {beforeEach, describe, expect, test} from "vitest";

import {callAs, db, resetFixture} from "./helpers.js";

beforeEach(resetFixture);

const exists = async (path: string) => (await db.doc(path).get()).exists;
const deleteHalaqa = (halaqaId: string) => callAs("admin", "deleteHalaqa", {halaqaId});

describe("deleteHalaqa", () => {
  test("an empty halaqa is deleted", async () => {
    await db.doc("halaqat/h3").set({name: "h3", teacherId: "t1"});

    expect(await deleteHalaqa("h3")).toMatchObject({ok: true});
    expect(await exists("halaqat/h3")).toBe(false);
    expect(await exists("halaqat/h1")).toBe(true);
  });

  test("a halaqa with students is refused (reason hasStudents) and kept", async () => {
    expect(await deleteHalaqa("h1")).toMatchObject({
      ok: false,
      code: "failed-precondition",
      details: {reason: "hasStudents"},
    });
    expect(await exists("halaqat/h1")).toBe(true);
  });

  test("a disabled student still counts", async () => {
    await db.doc("halaqat/h3").set({name: "h3", teacherId: "t1"});
    await db.doc("users/s2").update({halaqaId: "h3", disabled: true});

    expect(await deleteHalaqa("h3")).toMatchObject({
      ok: false,
      code: "failed-precondition",
      details: {reason: "hasStudents"},
    });
    expect(await exists("halaqat/h3")).toBe(true);
  });

  test("a recording still pointing to the halaqa is refused (reason hasRecordings)", async () => {
    await db.doc("halaqat/h3").set({name: "h3", teacherId: "t1"});
    await db.doc("recordings/stray").set({
      studentId: "s1",
      halaqaId: "h3",
      teacherId: "t1",
      storagePath: "recordings/s1/stray.mp3",
      createdAt: Timestamp.now(),
    });

    expect(await deleteHalaqa("h3")).toMatchObject({
      ok: false,
      code: "failed-precondition",
      details: {reason: "hasRecordings"},
    });
    expect(await exists("halaqat/h3")).toBe(true);
  });

  test("unknown halaqa -> not-found; bad id -> invalid-argument", async () => {
    expect(await deleteHalaqa("nope")).toMatchObject({ok: false, code: "not-found"});
    expect(await callAs("admin", "deleteHalaqa", {halaqaId: ""})).toMatchObject({
      ok: false,
      code: "invalid-argument",
    });
  });

  test("a teacher cannot delete even their own empty halaqa", async () => {
    await db.doc("halaqat/h3").set({name: "h3", teacherId: "t1"});

    expect(await callAs("t1", "deleteHalaqa", {halaqaId: "h3"})).toMatchObject({
      ok: false,
      code: "permission-denied",
    });
    expect(await exists("halaqat/h3")).toBe(true);
  });
});
