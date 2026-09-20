import { describe, expect, inject, test } from "vitest";

// tests/global-setup.ts makes the first request to this app, before any test file can
describe("On-demand start", () => {
  test("a request to a stopped app starts its container and gets the page", (context) => {
    const coldStart = inject("coldStart");
    context.skip(
      coldStart.before?.status === "running",
      `${coldStart.site}'s container was already running when the suite started; stop it to test the on-demand start`,
    );

    expect(
      coldStart.before,
      `${coldStart.site} has no container; create it with docker compose create`,
    ).toBeDefined();
    expect(["created", "exited"]).toContain(coldStart.before?.status);
    expect({ httpCode: coldStart.httpCode, error: coldStart.error }).toEqual({
      httpCode: 200,
      error: undefined,
    });
    // Caddy holds the request until the healthcheck passes
    expect(coldStart.after).toEqual({ status: "running", health: "healthy" });
  });
});
