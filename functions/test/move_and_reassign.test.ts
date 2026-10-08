import {beforeEach, describe, expect, test} from "vitest";

import {callAs, db, resetFixture} from "./helpers.js";

beforeEach(resetFixture);

async function recording(id: string) {
  return (await db.doc(`recordings/${id}`).get()).data()!;
}

describe("moveStudent", () => {
  test("moves the student and every recording to the new halaqa and teacher", async () => {
    const result = await callAs("admin", "moveStudent", {studentId: "s1", halaqaId: "h2"});
    expect(result).toEqual({ok: true, data: {recordingsUpdated: 2}});

    expect((await db.doc("users/s1").get()).data()!.halaqaId).toBe("h2");
    for (const id of ["r1", "r2"]) {
      expect(await recording(id)).toMatchObject({halaqaId: "h2", teacherId: "t2"});
    }
    // Other students' recordings are untouched.
    expect(await recording("r3")).toMatchObject({halaqaId: "h1", teacherId: "t1"});
  });

  test("unknown halaqa or student -> not-found; a teacher -> failed-precondition", async () => {
    expect(await callAs("admin", "moveStudent", {studentId: "s1", halaqaId: "nope"})).toMatchObject({
      ok: false,
      code: "not-found",
    });
    expect(await callAs("admin", "moveStudent", {studentId: "nobody", halaqaId: "h2"})).toMatchObject({
      ok: false,
      code: "not-found",
    });
    expect(await callAs("admin", "moveStudent", {studentId: "t1", halaqaId: "h2"})).toMatchObject({
      ok: false,
      code: "failed-precondition",
    });
  });
});

describe("changeHalaqaTeacher", () => {
  test("updates the halaqa and teacherId on all its recordings", async () => {
    const result = await callAs("admin", "changeHalaqaTeacher", {halaqaId: "h1", teacherId: "t2"});
    expect(result).toEqual({ok: true, data: {recordingsUpdated: 3}});

    expect((await db.doc("halaqat/h1").get()).data()!.teacherId).toBe("t2");
    for (const id of ["r1", "r2", "r3"]) {
      expect(await recording(id)).toMatchObject({halaqaId: "h1", teacherId: "t2"});
    }
    expect(await recording("r4")).toMatchObject({halaqaId: "h2", teacherId: "t2"});
  });

  test("the new teacher must be a teacher", async () => {
    for (const teacherId of ["s1", "admin"]) {
      expect(
        await callAs("admin", "changeHalaqaTeacher", {halaqaId: "h1", teacherId}),
      ).toMatchObject({ok: false, code: "failed-precondition"});
    }
    expect(
      await callAs("admin", "changeHalaqaTeacher", {halaqaId: "h1", teacherId: "nobody"}),
    ).toMatchObject({ok: false, code: "not-found"});
    expect((await db.doc("halaqat/h1").get()).data()!.teacherId).toBe("t1");
  });
});
