import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import {
  addDoc,
  arrayUnion,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  setDoc,
  updateDoc,
  where,
} from "firebase/firestore";
import { afterAll, beforeAll, beforeEach, describe, test } from "vitest";
import { anonymous, as, createTestEnv, seedFixtures } from "./fixtures.js";

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await createTestEnv();
});
beforeEach(() => seedFixtures(env));
afterAll(() => env.cleanup());

describe("unauthenticated", () => {
  test("cannot read anything", async () => {
    const db = anonymous(env);
    await assertFails(getDoc(doc(db, "users/s1")));
    await assertFails(getDoc(doc(db, "halaqat/h1")));
    await assertFails(getDocs(collection(db, "users")));
  });
});

describe("users", () => {
  test("student reads own doc, not another student's", async () => {
    const db = as(env, "s1", "student");
    await assertSucceeds(getDoc(doc(db, "users/s1")));
    await assertFails(getDoc(doc(db, "users/s2")));
    await assertFails(getDoc(doc(db, "users/t1")));
  });

  test("student cannot change role, halaqaId or username", async () => {
    const db = as(env, "s1", "student");
    await assertFails(updateDoc(doc(db, "users/s1"), { role: "admin" }));
    await assertFails(updateDoc(doc(db, "users/s1"), { halaqaId: "h2" }));
    await assertFails(updateDoc(doc(db, "users/s1"), { username: "x" }));
  });

  test("nobody changes disabled from the client, not even an admin", async () => {
    await assertFails(updateDoc(doc(as(env, "s1", "student"), "users/s1"), { disabled: true }));
    await assertFails(
      updateDoc(doc(as(env, "s1", "student"), "users/s1"), {
        fcmTokens: arrayUnion("tok"),
        disabled: true,
      }),
    );
    await assertFails(updateDoc(doc(as(env, "t1", "teacher"), "users/t1"), { disabled: true }));
    await assertFails(updateDoc(doc(as(env, "t1", "teacher"), "users/s1"), { disabled: true }));
    await assertFails(updateDoc(doc(as(env, "admin", "admin"), "users/s1"), { disabled: true }));
    await assertFails(updateDoc(doc(as(env, "admin", "admin"), "users/admin"), { disabled: true }));
  });

  test("user adds an fcm token to own doc only", async () => {
    const db = as(env, "s1", "student");
    await assertSucceeds(updateDoc(doc(db, "users/s1"), { fcmTokens: arrayUnion("tok") }));
    await assertFails(updateDoc(doc(db, "users/s2"), { fcmTokens: arrayUnion("tok") }));
    await assertFails(updateDoc(doc(db, "users/s1"), { fcmTokens: "tok" }));
  });

  test("fcmTokens must be at most 10 strings", async () => {
    const db = as(env, "s1", "student");
    const tokens = (n: number) => Array.from({ length: n }, (_, i) => `tok-${i}`);
    await assertSucceeds(updateDoc(doc(db, "users/s1"), { fcmTokens: tokens(10) }));
    await assertFails(updateDoc(doc(db, "users/s1"), { fcmTokens: tokens(11) }));
    await assertFails(updateDoc(doc(db, "users/s1"), { fcmTokens: ["ok", 7] }));
    await assertFails(updateDoc(doc(db, "users/s1"), { fcmTokens: [...tokens(9), null] }));
  });

  test("teacher t1 reads s1 (their student), not s3 or t2", async () => {
    const db = as(env, "t1", "teacher");
    await assertSucceeds(getDoc(doc(db, "users/s1")));
    await assertFails(getDoc(doc(db, "users/s3")));
    await assertFails(getDoc(doc(db, "users/t2")));
  });

  test("teacher lists students of own halaqa only (watchStudentsInHalaqa)", async () => {
    const db = as(env, "t1", "teacher");
    const students = (halaqaId: string) =>
      query(
        collection(db, "users"),
        where("halaqaId", "==", halaqaId),
        where("role", "==", "student"),
        orderBy("fullName"),
      );
    await assertSucceeds(getDocs(students("h1")));
    await assertFails(getDocs(students("h2")));
    await assertFails(getDocs(collection(db, "users")));
  });

  test("admin reads every user and lists by role", async () => {
    const db = as(env, "admin", "admin");
    await assertSucceeds(getDoc(doc(db, "users/s3")));
    await assertSucceeds(
      getDocs(query(collection(db, "users"), where("role", "==", "teacher"), orderBy("fullName"))),
    );
  });

  test("nobody creates or deletes a users doc from the client", async () => {
    const newUser = { username: "x", fullName: "x", role: "admin", fcmTokens: [] };
    await assertFails(setDoc(doc(as(env, "admin", "admin"), "users/new"), newUser));
    await assertFails(setDoc(doc(as(env, "new", "student"), "users/new"), newUser));
    await assertFails(setDoc(doc(anonymous(env), "users/new"), newUser));
    await assertFails(deleteDoc(doc(as(env, "admin", "admin"), "users/s1")));
  });

  test("progress subcollection is closed", async () => {
    await assertFails(getDoc(doc(as(env, "s1", "student"), "users/s1/progress/2")));
    await assertFails(getDoc(doc(as(env, "admin", "admin"), "users/s1/progress/2")));
  });
});

describe("halaqat", () => {
  test("teacher reads own halaqa, not another's", async () => {
    const db = as(env, "t1", "teacher");
    await assertSucceeds(getDoc(doc(db, "halaqat/h1")));
    await assertFails(getDoc(doc(db, "halaqat/h2")));
    await assertSucceeds(
      getDocs(query(collection(db, "halaqat"), where("teacherId", "==", "t1"), orderBy("name"))),
    );
  });

  test("student reads own halaqa only", async () => {
    const db = as(env, "s1", "student");
    await assertSucceeds(getDoc(doc(db, "halaqat/h1")));
    await assertFails(getDoc(doc(db, "halaqat/h2")));
  });

  test("teacher cannot create or rename a halaqa", async () => {
    const db = as(env, "t1", "teacher");
    await assertFails(addDoc(collection(db, "halaqat"), { name: "حلقة", teacherId: "t1" }));
    await assertFails(updateDoc(doc(db, "halaqat/h1"), { name: "جديد" }));
  });

  test("admin creates and renames halaqat", async () => {
    const db = as(env, "admin", "admin");
    await assertSucceeds(getDocs(query(collection(db, "halaqat"), orderBy("name"))));
    await assertSucceeds(addDoc(collection(db, "halaqat"), { name: "حلقة المغرب", teacherId: "t2" }));
    await assertSucceeds(updateDoc(doc(db, "halaqat/h1"), { name: "حلقة الضحى" }));
  });

  test("nobody deletes a halaqa from the client (deleteHalaqa function only)", async () => {
    await assertFails(deleteDoc(doc(as(env, "admin", "admin"), "halaqat/h2")));
    await assertFails(deleteDoc(doc(as(env, "t2", "teacher"), "halaqat/h2")));
    await assertFails(deleteDoc(doc(as(env, "s3", "student"), "halaqat/h2")));
  });

  test("the client cannot change a halaqa's teacher (changeHalaqaTeacher function only)", async () => {
    const db = as(env, "admin", "admin");
    await assertFails(updateDoc(doc(db, "halaqat/h1"), { teacherId: "t2" }));
    await assertFails(updateDoc(doc(db, "halaqat/h1"), { name: "حلقة الضحى", teacherId: "t2" }));
    await assertFails(updateDoc(doc(db, "halaqat/h1"), { name: "" }));
  });

  test("admin cannot create an invalid halaqa", async () => {
    const db = as(env, "admin", "admin");
    const halaqat = collection(db, "halaqat");
    await assertFails(addDoc(halaqat, { name: "حلقة", teacherId: "s1" })); // a student
    await assertFails(addDoc(halaqat, { name: "حلقة", teacherId: "nobody" }));
    await assertFails(addDoc(halaqat, { name: "", teacherId: "t1" }));
    await assertFails(addDoc(halaqat, { name: "ح".repeat(61), teacherId: "t1" }));
    await assertFails(addDoc(halaqat, { name: "حلقة", teacherId: "t1", extra: true }));
    await assertFails(updateDoc(doc(db, "halaqat/h1"), { teacherId: "s1" }));
  });
});
