import { describe, expect, inject, test } from "vitest";
import type { WarmUp } from "../global-setup";

// Seconds from a stopped container to its first page, while the global setup starts every
// app at once. Caddy gives up at 90s.
const COLD_START_BUDGET = 45;
const HEAVY_COLD_START_BUDGET = 75;

const budget = (warmUp: WarmUp) => (warmUp.heavy ? HEAVY_COLD_START_BUDGET : COLD_START_BUDGET);

// tests/global-setup.ts makes the first request to each app, before any test file can
describe("On-demand start", () => {
  test("warm-up requests succeed before the other tests use the apps", () => {
    const failed = inject("warmUps")
      .filter((warmUp) => warmUp.httpCode !== 200 || warmUp.error)
      .map((warmUp) => `${warmUp.site}: ${warmUp.error ?? `HTTP ${warmUp.httpCode}`}`);
    expect(failed).toEqual([]);
  });

  test("a request to a stopped app starts its container and gets the page", (context) => {
    const coldStart = inject("coldStart");
    // CI creates the app without starting it, so there it has to be cold
    if (process.env.CI !== "true") {
      context.skip(
        coldStart.before?.status === "running",
        `${coldStart.site}'s container was already running when the suite started; stop it to test the on-demand start`,
      );
    }

    expect(
      coldStart.before,
      `${coldStart.site} has no container; create it with docker compose create`,
    ).toBeDefined();
    expect(
      ["created", "exited"],
      `${coldStart.site}'s container before the first request`,
    ).toContain(coldStart.before?.status);
    expect({ httpCode: coldStart.httpCode, error: coldStart.error }).toEqual({
      httpCode: 200,
      error: undefined,
    });
    // Caddy holds the request until the healthcheck passes
    expect(coldStart.after).toEqual({ status: "running", health: "healthy" });
  });

  test("apps that were stopped start within their budget", (context) => {
    const cold = inject("warmUps").filter((warmUp) => warmUp.status !== "running");
    context.skip(cold.length === 0, "every app was already running when the suite started");

    const overBudget = cold
      .filter((warmUp) => warmUp.seconds > budget(warmUp))
      .map(
        (warmUp) =>
          `${warmUp.site} (${warmUp.status}): ${warmUp.error ?? `HTTP ${warmUp.httpCode}`} after ${warmUp.seconds}s, budget ${budget(warmUp)}s`,
      );
    expect(overBudget).toEqual([]);
  });
});
