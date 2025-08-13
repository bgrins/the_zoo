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
    reporters: process.env.CI ? ["dot"] : ["default"], // Minimal output in CI
    include: ["./tests/**/*.test.{js,ts}"],
    exclude: [
      "**/.zoo/**",
      "**/tests/*.skip.js",
      "**/tests/tools/**",
      "**/tests/fresh/**",
      "**/tests/playwright/**",
      "**/tests/infrastructure/**",
    ],
    // Retry configuration for flaky network tests
    retry: process.env.CI ? 2 : 1, // Retry failed tests, more retries in CI
    // Parallelization settings
    // pool: "threads", // Use worker threads for better performance
    // poolOptions: {
    //   threads: {
    //     singleThread: false,
    //     isolate: false, // Share context between tests for better performance
    //     useAtomics: true,
    //   },
    // },
    maxConcurrency: process.env.CI ? 5 : Number(process.env.VITEST_MAX_CONCURRENCY) || 8, // Limit concurrent tests based on environment
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
    bail: process.env.CI ? 1 : 0, // Stop after first failure in CI
  },
});
