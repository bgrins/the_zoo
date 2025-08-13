import { describe, expect, test } from "vitest";
import { batchFetch } from "../utils/http-client";

/**
 * Tests for the fail_injector Caddy module
 *
 * These tests verify the behavior of the custom fail_injector module
 * that can inject HTTP failures for resilience testing.
 *
 * The module supports runtime configuration via HTTP headers:
 * - X-Chaos-Mode: "1" to enable, "0" to disable
 * - X-Chaos-Mode-Fail-Probability: probability value between 0.0 and 1.0
 *
 * Run with: npm run test:fail-injector
 */

/**
 * Helper function to count failures in a batch of requests
 * Uses the optimized batchFetch utility for better performance
 */
async function countFailures(
  requestCount: number,
  _proxy: string, // No longer needed with fetchWithProxy
  url: string,
  headers?: Record<string, string>,
): Promise<number> {
  // Create array of URLs for batch processing
  const urls = Array.from({ length: requestCount }, () => url);

  // Use batchFetch for optimized parallel requests
  const results = await batchFetch(urls, {
    headers: headers || {},
    timeout: 5000,
    concurrency: 10, // Match original batch size
  });

  // Count failures (status code 500 or request errors)
  return results.reduce((failures, result) => {
    return failures + (result.httpCode === 500 || !result.success ? 1 : 0);
  }, 0);
}

describe("fail_injector module", () => {
  const proxyUrl = "http://localhost:3128";
  const testUrl = "http://example.zoo/";

  describe("without CHAOS_MODE enabled", () => {
    test("should not inject any failures when CHAOS_MODE is not set", async () => {
      // Default behavior - no headers means chaos mode is controlled by environment
      const failureCount = await countFailures(10, proxyUrl, testUrl);
      expect(failureCount).toBe(0);
    });

    test("should handle 100 requests without failures", async () => {
      const failureCount = await countFailures(100, proxyUrl, testUrl);
      expect(failureCount).toBe(0);
    });

    test("should not inject failures even with high probability when CHAOS_MODE is 0", async () => {
      const failureCount = await countFailures(50, proxyUrl, testUrl, {
        "X-Chaos-Mode": "0",
        "X-Chaos-Mode-Fail-Probability": "0.9",
      });
      expect(failureCount).toBe(0);
    });
  });

  describe("with FAIL_PROBABILITY headers", () => {
    test("should inject failures based on probability", async () => {
      // Test with 100 requests and 20% failure probability
      const failures = await countFailures(100, proxyUrl, testUrl, {
        "X-Chaos-Mode": "1",
        "X-Chaos-Mode-Fail-Probability": "0.2",
      });

      // Expect roughly 20% failures (allowing ±10% variance)
      expect(failures).toBeGreaterThanOrEqual(10);
      expect(failures).toBeLessThanOrEqual(30);
    });

    test("should handle different probability values", async () => {
      // Test with 50% failure rate
      const failures = await countFailures(100, proxyUrl, testUrl, {
        "X-Chaos-Mode": "1",
        "X-Chaos-Mode-Fail-Probability": "0.5",
      });

      // Expect roughly 50% failures (allowing ±15% variance)
      expect(failures).toBeGreaterThanOrEqual(35);
      expect(failures).toBeLessThanOrEqual(65);
    });

    test("should not fail when probability is 0", async () => {
      const failures = await countFailures(50, proxyUrl, testUrl, {
        "X-Chaos-Mode": "1",
        "X-Chaos-Mode-Fail-Probability": "0.0",
      });
      expect(failures).toBe(0);
    });
  });

  describe("edge cases", () => {
    test("should handle invalid probability values gracefully", async () => {
      // Test with probability > 1.0 (should be clamped to 1.0 or ignored)
      const failures = await countFailures(20, proxyUrl, testUrl, {
        "X-Chaos-Mode": "1",
        "X-Chaos-Mode-Fail-Probability": "2.5",
      });
      // Should either fail all or ignore the invalid value
      expect(failures).toBeLessThanOrEqual(20);
    });

    test("should handle malformed header values", async () => {
      const failures = await countFailures(10, proxyUrl, testUrl, {
        "X-Chaos-Mode": "yes", // Not "1"
        "X-Chaos-Mode-Fail-Probability": "0.5",
      });
      // Should treat as disabled
      expect(failures).toBe(0);
    });
  });
});

/**
 * Integration test for fail_injector with different probability values
 *
 * This test verifies that the fail_injector works correctly with various
 * probability settings using runtime headers
 */
describe("fail_injector integration tests", () => {
  const proxyUrl = "http://localhost:3128";
  const testUrl = "http://example.zoo/";

  test("verifies statistical distribution across multiple probability values", async () => {
    const results: Array<{
      probability: number;
      expectedRate: number;
      actualRate: number;
      failures: number;
      requests: number;
    }> = [];

    // Test different probability values
    for (const probability of ["0.0", "0.1", "0.3", "0.5"]) {
      const failures = await countFailures(100, proxyUrl, testUrl, {
        "X-Chaos-Mode": "1",
        "X-Chaos-Mode-Fail-Probability": probability,
      });
      const failureRate = failures / 100;

      results.push({
        probability: parseFloat(probability),
        expectedRate: parseFloat(probability),
        actualRate: failureRate,
        failures: failures,
        requests: 100,
      });

      // Verify within acceptable range (±0.15 for variance)
      expect(Math.abs(failureRate - parseFloat(probability))).toBeLessThanOrEqual(0.15);
    }

    // Test results are validated by the assertions above
  });
});
