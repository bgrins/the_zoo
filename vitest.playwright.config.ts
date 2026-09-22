import { defineConfig } from "vitest/config";
import { baseTest, cacheDir } from "./vitest.config";

// Browser tests are excluded from the default run; this config runs only them. There is no
// global warm-up: each file starts the on-demand apps it uses in beforeAll.
export default defineConfig({
  cacheDir,
  test: {
    ...baseTest,
    include: ["./tests/playwright/**/*.test.ts"],
    // Real browser flows (OAuth redirects and sign-ins) take longer
    testTimeout: 30000,
  },
});
