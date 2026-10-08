import {defineConfig} from "vitest/config";

export default defineConfig({
  test: {
    include: ["test/**/*.test.ts"],
    // Every file shares the same emulators; never run them in parallel.
    fileParallelism: false,
    // The first call to each function waits for the emulator to load it.
    testTimeout: 30000,
    hookTimeout: 30000,
  },
});
