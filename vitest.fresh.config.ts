import { readFileSync } from "node:fs";
import { parse } from "dotenv";
import { defineConfig } from "vitest/config";
import base from "./vitest.config";

// The fresh (unseeded) instance runs beside the main one with its own proxy port. Setting
// the env here, rather than inside a test, applies it before modules read ZOO_PROXY_PORT.
export default defineConfig({
  ...base,
  test: {
    ...base.test,
    include: ["./tests/fresh/**/*.test.ts"],
    exclude: [],
    env: parse(readFileSync(".env.fresh")),
  },
});
