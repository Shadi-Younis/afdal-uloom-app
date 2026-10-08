import {beforeEach, describe, expect, test} from "vitest";

import {PASSWORD, auth, callAs, db, emailFor, resetFixture, signIn} from "./helpers.js";

beforeEach(resetFixture);

const disabledField = async (uid: string) => (await db.doc(`users/${uid}`).get()).get("disabled");

describe("setUserDisabled", () => {
  test("disabling blocks sign-in and keeps the data; enabling restores it", async () => {
    expect(await callAs("admin", "setUserDisabled", {uid: "s2", disabled: true})).toMatchObject({
      ok: true,
    });
    expect((await auth.getUser("s2")).disabled).toBe(true);
    await expect(signIn(emailFor("s2"), PASSWORD)).rejects.toThrow(/USER_DISABLED/);
    expect((await db.doc("users/s2").get()).exists).toBe(true);
    expect((await db.doc("recordings/r3").get()).exists).toBe(true);

    expect(await callAs("admin", "setUserDisabled", {uid: "s2", disabled: false})).toMatchObject({
      ok: true,
    });
    await expect(signIn(emailFor("s2"), PASSWORD)).resolves.toBeTruthy();
  });

  test("updates users/{uid}.disabled together with the Auth account", async () => {
    expect(await disabledField("t2")).toBe(false);

    await callAs("admin", "setUserDisabled", {uid: "t2", disabled: true});
    expect(await disabledField("t2")).toBe(true);
    expect((await auth.getUser("t2")).disabled).toBe(true);

    await callAs("admin", "setUserDisabled", {uid: "t2", disabled: false});
    expect(await disabledField("t2")).toBe(false);
    expect((await auth.getUser("t2")).disabled).toBe(false);
  });

  test("admin cannot disable themselves", async () => {
    expect(await callAs("admin", "setUserDisabled", {uid: "admin", disabled: true})).toMatchObject({
      ok: false,
      code: "permission-denied",
    });
    expect((await auth.getUser("admin")).disabled).toBe(false);
    expect(await disabledField("admin")).toBe(false);
  });

  test("unknown user -> not-found; non-boolean -> invalid-argument", async () => {
    expect(await callAs("admin", "setUserDisabled", {uid: "nobody", disabled: true})).toMatchObject({
      ok: false,
      code: "not-found",
    });
    expect(await callAs("admin", "setUserDisabled", {uid: "s2", disabled: "yes"})).toMatchObject({
      ok: false,
      code: "invalid-argument",
    });
  });
});
