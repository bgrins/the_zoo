import { defineConfig } from "vitest/config";
import * as dotenv from "dotenv";

// Disable dotenv debug output
dotenv.config({ quiet: true });

export default defineConfig({
  cacheDir: ".vitest/cache",
  test: {
    globals: true,
    environment: "node",
    testTimeout: 10000,
    hookTimeout: 10000,
    // Minimal output in CI, with failures as annotations and retried tests in the job summary
    reporters: process.env.CI
      ? ["dot", "github-actions", "./tests/utils/flaky-summary-reporter.ts"]
      : ["default"],
    include: ["./tests/**/*.test.{js,ts}"],
    exclude: ["**/.zoo/**", "**/tests/*.skip.js", "**/tests/fresh/**", "**/tests/playwright/**"],
    // Starts every on-demand app before the tests, so none pays for a cold start
    globalSetup: ["./tests/global-setup.ts"],
    // Retry configuration for flaky network tests
    retry: process.env.CI ? 1 : 2,
    // Parallelization settings
    // pool: "threads", // Use worker threads for better performance
    // poolOptions: {
    //   threads: {
    //     singleThread: false,
    //     isolate: false, // Share context between tests for better performance
    //     useAtomics: true,
    //   },
    // },
    maxConcurrency: process.env.CI ? 3 : Number(process.env.VITEST_MAX_CONCURRENCY) || 8, // Limit concurrent tests based on environment
    // Test sequencing for service-dependent tests
    // sequence: {
    //   hooks: "list", // Run hooks in the order they're defined
    //   shuffle: false, // Don't randomize test order
    // },
    snapshotFormat: {
      printBasicPrototype: false,
      escapeString: false,
    },
    coverage: {
      enabled: false,
    },
  },
});
