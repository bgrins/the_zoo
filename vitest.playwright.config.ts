import { defineConfig } from "vitest/config";
import { baseTest, cacheDir } from "./vitest.config";

// Browser tests are excluded from the default run; this config runs only them.
export default defineConfig({
  cacheDir,
  test: {
    ...baseTest,
    include: ["./tests/playwright/**/*.test.ts"],
    // Real browser flows (OAuth redirects on top of an on-demand cold start) take longer
    testTimeout: 30000,
  },
});
