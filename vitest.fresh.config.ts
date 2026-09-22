import { readFileSync } from "node:fs";
import { parse } from "dotenv";
import { defineConfig } from "vitest/config";
import { baseTest, cacheDir } from "./vitest.config";

// The fresh (unseeded) instance runs beside the main one with its own proxy port. Setting
// the env here, rather than inside a test, applies it before modules read ZOO_PROXY_PORT.
// The fresh instance runs only the apps its tests use, so there is no global warm-up.
export default defineConfig({
  cacheDir,
  test: {
    ...baseTest,
    include: ["./tests/fresh/**/*.test.ts"],
    env: parse(readFileSync(".env.fresh")),
  },
});
