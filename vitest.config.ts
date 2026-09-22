import { defineConfig } from "vitest/config";
import * as dotenv from "dotenv";

// Disable dotenv debug output
dotenv.config({ quiet: true });

// Tests that need neither a Docker daemon nor a running zoo (some run `docker compose config`)
const OFFLINE_TESTS = [
  "./tests/cli/**/*.test.ts",
  "./tests/smoke/analytics-sites.test.ts",
  "./tests/smoke/docker-compose-file.test.ts",
  "./tests/smoke/docker-compose-utils.test.ts",
  "./tests/smoke/firefox-profile.test.ts",
  "./tests/smoke/golden-state.test.ts",
  "./tests/smoke/test-go-script.test.ts",
];

// npm run test:playwright and test:fresh run these with their own configs
const OWN_CONFIG_TESTS = ["./tests/playwright/**", "./tests/fresh/**"];

// Shared with vitest.playwright.config.ts and vitest.fresh.config.ts
export const baseTest = {
  globals: true,
  environment: "node",
  testTimeout: 10000,
  hookTimeout: 10000,
  // Minimal output in CI, with failures as annotations and retried tests in the job summary
  reporters: process.env.CI
    ? ["dot", "github-actions", "./tests/utils/flaky-summary-reporter.ts"]
    : ["default"],
  // Retry configuration for flaky network tests
  retry: process.env.CI ? 1 : 2,
  maxConcurrency: process.env.CI ? 3 : Number(process.env.VITEST_MAX_CONCURRENCY) || 8, // Limit concurrent tests based on environment
  snapshotFormat: {
    printBasicPrototype: false,
    escapeString: false,
  },
};

export const cacheDir = ".vitest/cache";

export default defineConfig({
  cacheDir,
  test: {
    ...baseTest,
    projects: [
      {
        extends: true,
        // Many CLI tests run the CLI through tsx, which takes seconds when they run in parallel
        test: { name: "offline", include: OFFLINE_TESTS, testTimeout: 30_000 },
      },
      {
        extends: true,
        test: {
          name: "live",
          // Negated globs rather than exclude, which would drop the command line's --exclude
          include: [
            "./tests/**/*.test.ts",
            ...[...OFFLINE_TESTS, ...OWN_CONFIG_TESTS].map((glob) => `!${glob}`),
          ],
          // Starts every on-demand app before the tests, so none pays for a cold start
          globalSetup: ["./tests/global-setup.ts"],
        },
      },
    ],
  },
});
