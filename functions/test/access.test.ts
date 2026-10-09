import {beforeEach, describe, expect, test} from "vitest";

import {call, callAs, resetFixture} from "./helpers.js";

beforeEach(resetFixture);

// A valid-looking request for each function, so a denial can only come from
// the caller check.
const requests: Record<string, unknown> = {
  createUser: {
    username: "new.student",
    password: "secret123",
    fullName: "طالب جديد",
    role: "student",
    halaqaId: "h1",
    studentCode: "S100",
  },
  resetPassword: {uid: "s1", newPassword: "secret123"},
  moveStudent: {studentId: "s1", halaqaId: "h2"},
  changeHalaqaTeacher: {halaqaId: "h1", teacherId: "t2"},
  setUserDisabled: {uid: "s2", disabled: true},
  deleteHalaqa: {halaqaId: "h2"},
  deleteUser: {uid: "s2"},
  updateUserProfile: {uid: "s1", fullName: "اسم جديد"},
};

describe("callers", () => {
  for (const [name, data] of Object.entries(requests)) {
    test(`${name}: unauthenticated -> unauthenticated`, async () => {
      expect(await call(name, data)).toMatchObject({ok: false, code: "unauthenticated"});
    });

    test(`${name}: student -> permission-denied`, async () => {
      expect(await callAs("s1", name, data)).toMatchObject({
        ok: false,
        code: "permission-denied",
      });
    });
  }

  const adminOnly = ["moveStudent", "changeHalaqaTeacher", "setUserDisabled", "deleteHalaqa", "deleteUser"];
  for (const name of adminOnly) {
    test(`${name}: teacher -> permission-denied (admin only)`, async () => {
      expect(await callAs("t1", name, requests[name])).toMatchObject({
        ok: false,
        code: "permission-denied",
      });
    });
  }

  test("a non-object payload -> invalid-argument", async () => {
    expect(await callAs("admin", "setUserDisabled", "s2")).toMatchObject({
      ok: false,
      code: "invalid-argument",
    });
  });
});
