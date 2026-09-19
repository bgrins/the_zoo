import { defineConfig } from "vitest/config";
import base from "./vitest.config";

// Browser tests are excluded from the default run; this config runs only them.
export default defineConfig({
  ...base,
  test: {
    ...base.test,
    include: ["./tests/playwright/**/*.test.ts"],
    exclude: [],
  },
});
