import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Every file shares one emulator database; never run them in parallel.
    fileParallelism: false,
    testTimeout: 20000,
    hookTimeout: 30000,
  },
});
