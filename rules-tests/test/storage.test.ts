// storage.rules: recording audio under recordings/{studentId}/{id}.{ext},
// checked against the recordings/{id} document (cross-service rules).
import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { afterAll, beforeAll, beforeEach, describe, test } from "vitest";
import { clearAllStorage, createTestEnv, seedFixtures, storageAs, type Role, type Storage } from "./fixtures.js";

let env: RulesTestEnvironment;

// The fixture's recording documents (see fixtures.ts) and their files.
const R_S1 = "recordings/s1/r-s1.mp3"; // official, s1, teacher t1, uploadedBy t1
const R_S3 = "recordings/s3/r-s3.mp3"; // official, s3, teacher t2, uploadedBy t2
const P_S1 = "recordings/s1/p-s1.m4a"; // practice, s1, teacher t1, uploadedBy s1

const MiB = 1024 * 1024;
const audio = (size = 1024) => new Uint8Array(size).fill(7);

// async: an UploadTask is a thenable, not a Promise.
const upload = async (storage: Storage, path: string, contentType = "audio/mpeg", data = audio()) =>
  storage.ref(path).put(data, { contentType });

const read = (storage: Storage, path: string) => storage.ref(path).getDownloadURL();

const as = (uid: string, role: Role) => storageAs(env, uid, role);

/** Puts the file of each path with rules off, as the cleanup / seed would. */
async function existingFiles(...paths: string[]) {
  await env.withSecurityRulesDisabled(async (context) => {
    for (const path of paths) {
      await context.storage().ref(path).put(audio(), { contentType: "audio/mpeg" });
    }
  });
}

beforeAll(async () => {
  env = await createTestEnv();
});
beforeEach(async () => {
  await clearAllStorage(env);
  await seedFixtures(env);
});
afterAll(() => env.cleanup());

describe("read", () => {
  beforeEach(() => existingFiles(R_S1, R_S3, P_S1));

  test("the student of the recording reads its files", async () => {
    await assertSucceeds(read(as("s1", "student"), R_S1));
    await assertSucceeds(read(as("s1", "student"), P_S1));
  });

  test("another student is denied", async () => {
    await assertFails(read(as("s2", "student"), R_S1));
    await assertFails(read(as("s3", "student"), P_S1));
  });

  test("the teacher of the halaqa reads, another teacher is denied", async () => {
    await assertSucceeds(read(as("t1", "teacher"), R_S1));
    await assertSucceeds(read(as("t1", "teacher"), P_S1));
    await assertFails(read(as("t2", "teacher"), R_S1));
    await assertSucceeds(read(as("t2", "teacher"), R_S3));
  });

  test("teacherId alone is not enough: the teacher role is required", async () => {
    await assertFails(read(as("t1", "student"), R_S1));
  });

  test("the admin reads every file", async () => {
    await assertSucceeds(read(as("admin", "admin"), R_S1));
    await assertSucceeds(read(as("admin", "admin"), R_S3));
  });

  test("signed out is denied", async () => {
    await assertFails(read(env.unauthenticatedContext().storage(), R_S1));
  });

  test("a file no document points at is admin-only", async () => {
    // Same recording id, other folder or extension than its storagePath.
    await existingFiles("recordings/s1/r-s1.wav", "recordings/s2/r-s1.mp3");
    await assertFails(read(as("s1", "student"), "recordings/s1/r-s1.wav"));
    await assertFails(read(as("t1", "teacher"), "recordings/s2/r-s1.mp3"));
    await assertSucceeds(read(as("admin", "admin"), "recordings/s1/r-s1.wav"));
  });

  test("nothing outside recordings/ is readable, not even by the admin", async () => {
    await existingFiles("other/file.mp3");
    await assertFails(read(as("admin", "admin"), "other/file.mp3"));
  });
});

describe("create", () => {
  test("the uploader of the document uploads to its storagePath", async () => {
    await assertSucceeds(upload(as("t1", "teacher"), R_S1));
    await assertSucceeds(upload(as("s1", "student"), P_S1, "audio/mp4"));
  });

  test("denied without a recording document", async () => {
    await assertFails(upload(as("t1", "teacher"), "recordings/s1/no-doc.mp3"));
    await assertFails(upload(as("admin", "admin"), "recordings/s1/no-doc.mp3"));
  });

  test("denied on a path that differs from storagePath", async () => {
    const t1 = as("t1", "teacher");
    await assertFails(upload(t1, "recordings/s1/r-s1.m4a", "audio/mp4"));
    await assertFails(upload(t1, "recordings/s2/r-s1.mp3"));
    await assertFails(upload(t1, "recordings/s1/r-s1.mp3.mp3"));
  });

  test("denied for anyone but uploadedBy, the admin included", async () => {
    await assertFails(upload(as("s1", "student"), R_S1));
    await assertFails(upload(as("t2", "teacher"), R_S1));
    await assertFails(upload(as("admin", "admin"), R_S1));
    await assertFails(upload(as("t1", "teacher"), P_S1, "audio/mp4"));
    await assertFails(upload(env.unauthenticatedContext().storage(), R_S1));
  });

  test("denied for a content type that is not audio", async () => {
    const t1 = as("t1", "teacher");
    await assertFails(upload(t1, R_S1, "text/plain"));
    await assertFails(upload(t1, R_S1, "video/mp4"));
    await assertFails(upload(t1, R_S1, "application/octet-stream"));
  });

  test("denied for an empty file", async () => {
    await assertFails(upload(as("t1", "teacher"), R_S1, "audio/mpeg", new Uint8Array(0)));
  });

  test("up to just under 100 MiB is allowed (more than 30 MB)", async () => {
    await assertSucceeds(upload(as("t1", "teacher"), R_S1, "audio/mpeg", audio(100 * MiB - 1)));
  }, 120_000);

  test("100 MiB or more is denied", async () => {
    await assertFails(upload(as("t1", "teacher"), R_S1, "audio/mpeg", audio(100 * MiB)));
  }, 120_000);

  test("overwriting an existing file is denied", async () => {
    await existingFiles(R_S1);
    await assertFails(upload(as("t1", "teacher"), R_S1));
  });
});

describe("update and delete", () => {
  beforeEach(() => existingFiles(R_S1, P_S1));

  test("no client may delete a file", async () => {
    await assertFails(as("t1", "teacher").ref(R_S1).delete());
    await assertFails(as("s1", "student").ref(P_S1).delete());
    await assertFails(as("admin", "admin").ref(R_S1).delete());
  });

  test("no client may change a file's metadata", async () => {
    await assertFails(as("t1", "teacher").ref(R_S1).updateMetadata({ contentType: "audio/wav" }));
    await assertFails(as("admin", "admin").ref(R_S1).updateMetadata({ cacheControl: "no-store" }));
  });
});
