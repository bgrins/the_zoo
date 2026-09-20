import { describe, expect, test } from "vitest";
import { batchFetch } from "../../scripts/lib/http-client";

/**
 * Tests for the fail_injector Caddy module, driven by its runtime headers:
 * - X-Chaos-Mode: "1" enables injection for the request, anything else disables it
 * - X-Chaos-Mode-Fail-Probability: 0.0-1.0; out-of-range values are ignored
 * While CHAOS_MODE=1 they count only with CHAOS_MODE_ALLOW_HEADER=1; these tests run with
 * chaos mode off (the default).
 */

const TEST_URL = "http://example.zoo/";
const INJECTED_BODY = "Intentional failure injected by fail_injector";

/** Count responses that the injector failed. Any other error fails the test. */
async function countInjected(requestCount: number, headers: Record<string, string> = {}) {
  const results = await batchFetch(
    Array.from({ length: requestCount }, () => TEST_URL),
    { headers, timeout: 5000, concurrency: 10 },
  );

  let injected = 0;
  for (const result of results) {
    expect(result.success, result.error).toBe(true);
    if (result.httpCode === 500 && result.body === INJECTED_BODY) {
      injected++;
    } else {
      expect(result.httpCode).toBe(200);
    }
  }
  return injected;
}

// Allow 5 standard deviations of binomial noise so the check essentially never flakes
function expectRoughly(injected: number, requests: number, probability: number) {
  const slack = 5 * Math.sqrt(requests * probability * (1 - probability));
  expect(injected).toBeGreaterThanOrEqual(requests * probability - slack);
  expect(injected).toBeLessThanOrEqual(requests * probability + slack);
}

describe("fail_injector module", () => {
  test("injects nothing when chaos mode is off (the default)", async () => {
    expect(await countInjected(100)).toBe(0);
  });

  test("X-Chaos-Mode: 0 disables injection even with a high probability", async () => {
    expect(
      await countInjected(50, { "X-Chaos-Mode": "0", "X-Chaos-Mode-Fail-Probability": "0.9" }),
    ).toBe(0);
  });

  test("only X-Chaos-Mode: 1 enables injection", async () => {
    expect(
      await countInjected(50, { "X-Chaos-Mode": "yes", "X-Chaos-Mode-Fail-Probability": "1" }),
    ).toBe(0);
  });

  test("probability 0 injects nothing and probability 1 fails every request", async () => {
    expect(
      await countInjected(50, { "X-Chaos-Mode": "1", "X-Chaos-Mode-Fail-Probability": "0.0" }),
    ).toBe(0);
    expect(
      await countInjected(50, { "X-Chaos-Mode": "1", "X-Chaos-Mode-Fail-Probability": "1.0" }),
    ).toBe(50);
  });

  test("injects failures at the requested probability", async () => {
    for (const probability of [0.2, 0.5]) {
      const injected = await countInjected(200, {
        "X-Chaos-Mode": "1",
        "X-Chaos-Mode-Fail-Probability": String(probability),
      });
      expectRoughly(injected, 200, probability);
    }
  });

  test("an out-of-range probability is ignored rather than clamped to 1", async () => {
    // Falls back to CHAOS_MODE_FAIL_PROBABILITY (0.2 by default), so not every request fails
    const injected = await countInjected(50, {
      "X-Chaos-Mode": "1",
      "X-Chaos-Mode-Fail-Probability": "2.5",
    });
    expect(injected).toBeLessThan(50);
  });
});
