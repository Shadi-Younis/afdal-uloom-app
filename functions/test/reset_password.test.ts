import {beforeEach, describe, expect, test} from "vitest";

import {PASSWORD, callAs, emailFor, resetFixture, signIn} from "./helpers.js";

beforeEach(resetFixture);

const reset = (caller: string, uid: string, newPassword = "brand-new-1") =>
  callAs(caller, "resetPassword", {uid, newPassword});

describe("resetPassword", () => {
  test("teacher resets own student; the new password works, the old one not", async () => {
    expect(await reset("t1", "s1")).toMatchObject({ok: true});
    await expect(signIn(emailFor("s1"), "brand-new-1")).resolves.toBeTruthy();
    await expect(signIn(emailFor("s1"), PASSWORD)).rejects.toThrow();
  });

  test("teacher cannot reset another teacher's student, a teacher or a missing user", async () => {
    for (const uid of ["s3", "t2", "admin", "nobody"]) {
      expect(await reset("t1", uid), uid).toMatchObject({ok: false, code: "permission-denied"});
    }
    await expect(signIn(emailFor("s3"), PASSWORD)).resolves.toBeTruthy();
  });

  test("admin resets any student or teacher", async () => {
    expect(await reset("admin", "s3")).toMatchObject({ok: true});
    expect(await reset("admin", "t2")).toMatchObject({ok: true});
    await expect(signIn(emailFor("t2"), "brand-new-1")).resolves.toBeTruthy();
  });

  test("admin resets own password", async () => {
    expect(await reset("admin", "admin")).toMatchObject({ok: true});
    await expect(signIn(emailFor("admin"), "brand-new-1")).resolves.toBeTruthy();
  });

  test("short password -> invalid-argument; missing user -> not-found", async () => {
    expect(await reset("admin", "s1", "12345")).toMatchObject({
      ok: false,
      code: "invalid-argument",
    });
    expect(await reset("admin", "nobody")).toMatchObject({ok: false, code: "not-found"});
  });
});
