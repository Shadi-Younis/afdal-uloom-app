import {beforeEach, describe, expect, test} from "vitest";

import {
  PASSWORD,
  addSecondAdmin,
  auth,
  callAs,
  db,
  emailFor,
  resetFixture,
  signIn,
} from "./helpers.js";

beforeEach(resetFixture);

const update = (caller: string, data: Record<string, unknown>) =>
  callAs(caller, "updateUserProfile", data);
const userDoc = async (uid: string) => (await db.doc(`users/${uid}`).get()).data()!;

describe("updateUserProfile: admin", () => {
  test("changes a student's name, username and code; the new username signs in", async () => {
    expect(
      await update("admin", {
        uid: "s1",
        fullName: "  اسم جديد ",
        username: " Ali.New ",
        studentCode: "S150",
      }),
    ).toMatchObject({ok: true});

    expect(await userDoc("s1")).toMatchObject({
      fullName: "اسم جديد",
      username: "ali.new",
      studentCode: "S150",
      role: "student",
      halaqaId: "h1",
    });
    const user = await auth.getUser("s1");
    expect(user.email).toBe(emailFor("ali.new"));
    expect(user.displayName).toBe("اسم جديد");
    await expect(signIn(emailFor("ali.new"), PASSWORD)).resolves.toBeTruthy();
    await expect(signIn(emailFor("s1"), PASSWORD)).rejects.toThrow();
  });

  test("a taken username -> already-exists (username); nothing changes", async () => {
    expect(await update("admin", {uid: "s1", fullName: "اسم جديد", username: "admin"})).toMatchObject({
      ok: false,
      code: "already-exists",
      details: {field: "username"},
    });
    expect(await userDoc("s1")).toMatchObject({fullName: "name s1", username: "s1"});
    expect((await auth.getUser("s1")).email).toBe(emailFor("s1"));
  });

  test("a taken studentCode -> already-exists (studentCode); nothing changes", async () => {
    expect(await update("admin", {uid: "s1", username: "s1.new", studentCode: "S002"})).toMatchObject({
      ok: false,
      code: "already-exists",
      details: {field: "studentCode"},
    });
    expect(await userDoc("s1")).toMatchObject({studentCode: "S001", username: "s1"});
    expect((await auth.getUser("s1")).email).toBe(emailFor("s1"));
  });

  test("keeping one's own studentCode or username is fine", async () => {
    expect(await update("admin", {uid: "s1", studentCode: "S001"})).toMatchObject({ok: true});
    expect(await update("admin", {uid: "admin", username: "admin"})).toMatchObject({ok: true});
    await expect(signIn(emailFor("admin"), PASSWORD)).resolves.toBeTruthy();
  });

  test("edits a teacher, another admin and themselves", async () => {
    await addSecondAdmin();
    expect(await update("admin", {uid: "t1", fullName: "الشيخ الجديد"})).toMatchObject({ok: true});
    expect(await update("admin", {uid: "admin2", fullName: "مدير ثان"})).toMatchObject({ok: true});
    expect(await update("admin", {uid: "admin", username: "manager"})).toMatchObject({ok: true});

    expect((await userDoc("t1")).fullName).toBe("الشيخ الجديد");
    expect((await userDoc("admin2")).fullName).toBe("مدير ثان");
    expect(await userDoc("admin")).toMatchObject({username: "manager", role: "admin"});
    await expect(signIn(emailFor("manager"), PASSWORD)).resolves.toBeTruthy();
    // The role never changes.
    expect((await auth.getUser("admin")).customClaims).toEqual({role: "admin"});
  });

  test("invalid input -> invalid-argument", async () => {
    const bad = [
      {uid: "s1"}, // nothing to update
      {uid: "s1", fullName: "ا"},
      {uid: "s1", fullName: "ا".repeat(61)},
      {uid: "s1", username: "has space"},
      {uid: "s1", username: "ab"},
      {uid: "s1", studentCode: "X100"},
      {uid: "s1", studentCode: "S12"},
      {uid: "t1", studentCode: "S300"}, // teachers have no code
      {uid: "s1", role: "admin"}, // ignored, so nothing to update
    ];
    for (const data of bad) {
      expect(await update("admin", data), JSON.stringify(data)).toMatchObject({
        ok: false,
        code: "invalid-argument",
      });
    }
    expect(await userDoc("s1")).toMatchObject({fullName: "name s1", role: "student"});
  });

  test("unknown user -> not-found", async () => {
    expect(await update("admin", {uid: "nobody", fullName: "اسم"})).toMatchObject({
      ok: false,
      code: "not-found",
    });
  });
});

describe("updateUserProfile: teacher", () => {
  test("changes the name of their own student", async () => {
    expect(await update("t1", {uid: "s2", fullName: "اسم من المعلم"})).toMatchObject({ok: true});
    expect((await userDoc("s2")).fullName).toBe("اسم من المعلم");
  });

  test("cannot change a username or code, nor edit anyone else", async () => {
    const denied = [
      {uid: "s1", username: "s1.new"},
      {uid: "s1", studentCode: "S150"},
      {uid: "s3", fullName: "اسم"}, // another teacher's student
      {uid: "t2", fullName: "اسم"},
      {uid: "t1", fullName: "اسم"}, // themselves
      {uid: "admin", fullName: "اسم"},
      {uid: "nobody", fullName: "اسم"},
    ];
    for (const data of denied) {
      expect(await update("t1", data), JSON.stringify(data)).toMatchObject({
        ok: false,
        code: "permission-denied",
      });
    }
    expect(await userDoc("s3")).toMatchObject({fullName: "name s3"});
    expect(await userDoc("s1")).toMatchObject({username: "s1", studentCode: "S001"});
  });
});
