import {beforeEach, describe, expect, test} from "vitest";

import {auth, callAs, db, emailFor, resetFixture, signIn} from "./helpers.js";

beforeEach(resetFixture);

const student = {
  username: "s100",
  password: "secret123",
  fullName: "يوسف أحمد",
  role: "student",
  halaqaId: "h1",
  studentCode: "S100",
};

describe("createUser", () => {
  test("admin creates a student: Auth user, role claim and users doc", async () => {
    const result = await callAs("admin", "createUser", {
      ...student,
      username: "  S100.Ali ", // trimmed and lower-cased
    });
    expect(result.ok).toBe(true);
    const {uid} = (result as {data: {uid: string}}).data;
    expect(uid).not.toBe("s100.ali"); // Auth generates the uid

    const user = await auth.getUser(uid);
    expect(user.email).toBe(emailFor("s100.ali"));
    expect(user.customClaims).toEqual({role: "student"});

    const doc = (await db.doc(`users/${uid}`).get()).data()!;
    expect(Object.keys(doc).sort()).toEqual(
      [
        "createdAt",
        "disabled",
        "fcmTokens",
        "fullName",
        "halaqaId",
        "role",
        "studentCode",
        "username",
      ],
    );
    expect(doc).toMatchObject({
      username: "s100.ali",
      fullName: "يوسف أحمد",
      role: "student",
      studentCode: "S100",
      halaqaId: "h1",
      fcmTokens: [],
      disabled: false,
    });
    expect(doc.createdAt.toDate().getTime()).toBeGreaterThan(Date.now() - 60_000);

    // The new account signs in with its password.
    await expect(signIn(emailFor("s100.ali"), "secret123")).resolves.toBeTruthy();
  });

  test("admin creates a teacher without halaqa or studentCode", async () => {
    const result = await callAs("admin", "createUser", {
      username: "t03",
      password: "secret123",
      fullName: "الشيخ أحمد",
      role: "teacher",
    });
    expect(result.ok).toBe(true);
    const {uid} = (result as {data: {uid: string}}).data;
    expect(await db.doc(`users/${uid}`).get().then((d) => d.data())).toMatchObject({
      role: "teacher",
      halaqaId: null,
      studentCode: null,
      disabled: false,
    });
    expect((await auth.getUser(uid)).customClaims).toEqual({role: "teacher"});
  });

  test("teacher creates a student in own halaqa", async () => {
    expect(await callAs("t1", "createUser", student)).toMatchObject({ok: true});
  });

  test("teacher cannot create a student in another halaqa", async () => {
    expect(await callAs("t1", "createUser", {...student, halaqaId: "h2"})).toMatchObject({
      ok: false,
      code: "permission-denied",
    });
  });

  test("teacher cannot create a teacher or an admin", async () => {
    const teacher = {username: "t09", password: "secret123", fullName: "معلم", role: "teacher"};
    expect(await callAs("t1", "createUser", teacher)).toMatchObject({
      ok: false,
      code: "permission-denied",
    });
    expect(await callAs("t1", "createUser", {...teacher, role: "admin"})).toMatchObject({
      ok: false,
      code: "permission-denied",
    });
  });

  test("duplicate username -> already-exists (any case)", async () => {
    expect(await callAs("admin", "createUser", student)).toMatchObject({ok: true});
    const again = await callAs("admin", "createUser", {
      ...student,
      username: "S100",
      studentCode: "S101",
    });
    expect(again).toMatchObject({ok: false, code: "already-exists", details: {field: "username"}});
  });

  test("duplicate studentCode -> already-exists, and no Auth user is left behind", async () => {
    const before = (await auth.listUsers()).users.length;
    const result = await callAs("admin", "createUser", {...student, studentCode: "S001"});
    expect(result).toMatchObject({
      ok: false,
      code: "already-exists",
      details: {field: "studentCode"},
    });
    expect((await auth.listUsers()).users.length).toBe(before);
  });

  test("invalid input -> invalid-argument", async () => {
    const invalid: Record<string, unknown>[] = [
      {...student, username: "ab"}, // too short
      {...student, username: "a".repeat(21)},
      {...student, username: "يوسف"}, // not [a-z0-9._-]
      {...student, username: "has space"},
      {...student, password: "12345"}, // short password
      {...student, password: "x".repeat(65)},
      {...student, fullName: "ي"},
      {...student, role: "parent"},
      {...student, halaqaId: undefined}, // missing halaqaId
      {...student, studentCode: undefined},
      {...student, studentCode: "s100"},
      {...student, studentCode: "S12"},
      {...student, role: "teacher"}, // teachers have no halaqaId / studentCode
      {...student, password: 123456},
    ];
    for (const data of invalid) {
      const result = await callAs("admin", "createUser", data);
      expect(result, JSON.stringify(data)).toMatchObject({ok: false, code: "invalid-argument"});
    }
  });

  test("unknown halaqa -> not-found", async () => {
    expect(await callAs("admin", "createUser", {...student, halaqaId: "nope"})).toMatchObject({
      ok: false,
      code: "not-found",
    });
  });
});
