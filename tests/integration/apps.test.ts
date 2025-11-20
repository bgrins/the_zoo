import { describe, expect, test } from "vitest";
import { getAllSites, type Site } from "../../scripts/sites-registry";
import { testUrl, fetchWithProxy } from "../utils/http-client";
import { ON_DEMAND_TIMEOUT } from "../constants";

// Load sites before test suite runs
const allSites = getAllSites();
const testSites = allSites
  .filter((site: Site) => site.type !== "static") // Exclude static sites - they're tested in smoke tests
  .map((site: Site) => ({
    ...site,
    url: site.httpHealthUrl,
    httpsUrl: site.httpsHealthUrl,
  }));

const activeSites = testSites.filter((s: any) => !s.onDemand);
const onDemandSites = testSites.filter((s: any) => s.onDemand);

describe.sequential("Dynamic Apps and On-Demand Services", () => {
  describe.concurrent("Site Availability - Active Sites", () => {
    // Generate a test for each active site
    activeSites.forEach((site: any) => {
      test(`${site.domain} should return valid status code`, { timeout: 2500 }, async () => {
        const expectStatus = site.domain === "mail-api.zoo" ? [200, 302, 401] : [200, 302];
        const result = await testUrl(site.url, {
          expectStatus,
          method: "GET",
        });

        expect(
          result.success,
          `Request to ${site.domain} failed: ${result.error || "Unknown error"}`,
        ).toBe(true);

        expect(
          result.statusOk,
          `Expected ${site.domain} to return HTTP ${expectStatus.join(" or ")} but got ${result.httpCode}`,
        ).toBe(true);
      });
    });
  });

  describe("Site Availability - On-Demand Sites", () => {
    // Ensure we have on-demand sites to test
    if (onDemandSites.length === 0) {
      throw new Error(
        "No on-demand sites found in the registry. Expected at least one on-demand site.",
      );
    }

    // Generate a test for each on-demand site with reasonable timeout
    onDemandSites.forEach((site: any) => {
      test(
        `${site.domain} should return valid status code`,
        { timeout: ON_DEMAND_TIMEOUT },
        async () => {
          const result = await testUrl(site.url, {
            expectStatus: [200, 302],
            method: "GET", // Use GET for on-demand to trigger container startup
            timeout: ON_DEMAND_TIMEOUT, // Longer timeout for on-demand services
          });

          expect(
            result.success,
            `Request to ${site.domain} failed: ${result.error || "Unknown error"}`,
          ).toBe(true);

          expect(
            result.statusOk,
            `Expected ${site.domain} to return HTTP 200 or 302 but got ${result.httpCode}`,
          ).toBe(true);
        },
      );
    });
  });

  describe("HTTPS Support", () => {
    const httpsSampleSites = activeSites.slice(0, 2);

    httpsSampleSites.forEach((site: any) => {
      test(`${site.domain} should support HTTPS`, { timeout: 2500 }, async () => {
        const result = await testUrl(site.httpsUrl, {
          expectStatus: [200],
          method: "GET",
        });

        expect(
          result.success,
          `HTTPS request to ${site.domain} failed: ${result.error || "Unknown error"}`,
        ).toBe(true);

        expect(
          result.httpCode,
          `Expected ${site.domain} to return HTTP 200 but got ${result.httpCode}`,
        ).toBe(200);
      });
    });

    describe("Response Validation", () => {
      test.concurrent("should serve correct content types and headers", async () => {
        // Combined content type and header tests
        const tests = [
          testUrl("http://performance.zoo/shared.js", {
            expectContentType: "javascript",
          }),
          testUrl("http://miniflux.zoo/", {
            expectContentType: "text/html",
            expectHeaders: ["x-performance-zoo"],
          }),
          testUrl("http://search-api.zoo/health", {
            expectContentType: "application/json",
          }),
          testUrl("http://wiki.zoo/", {
            expectContentType: "text/html",
          }),
        ];

        const results = await Promise.all(tests);

        results.forEach((result) => {
          // Build detailed error message for failures
          if (!result.allOk) {
            const failures = [];
            if (!result.statusOk) {
              failures.push(
                `HTTP status ${result.httpCode} (expected ${result.expectStatus || "200/302"})`,
              );
            }
            if (!result.contentTypeOk) {
              failures.push(
                `Content-Type '${result.contentType}' (expected to contain '${result.expectContentType}')`,
              );
            }
            if (!result.headersOk) {
              const missingHeaders =
                result.expectHeaders?.filter((h: string) => !result.headers[h]) || [];
              failures.push(`Missing headers: ${missingHeaders.join(", ")}`);
            }

            throw new Error(`${result.url} validation failed:\n  ${failures.join("\n  ")}`);
          }

          // Additional header validations
          if (result.headers["x-performance-zoo"]) {
            expect(
              result.headers["x-performance-zoo"],
              `${result.url}: x-performance-zoo header should contain 'injected' but was '${result.headers["x-performance-zoo"]}'`,
            ).toContain("injected");
          }
          if (result.headers["content-encoding"]) {
            expect(
              result.headers["content-encoding"],
              `${result.url}: content-encoding should contain 'gzip' but was '${result.headers["content-encoding"]}'`,
            ).toContain("gzip");
          }
        });
      });

      test("should inject performance.zoo script with various Accept-Encoding headers", async () => {
        // Test script injection works with different compression preferences
        // This ensures the bug where gzip requests broke injection doesn't regress
        const encodings = [
          { name: "no encoding", header: undefined },
          { name: "gzip", header: "gzip" },
          { name: "multiple encodings", header: "gzip, deflate, br" },
          { name: "identity", header: "identity" },
        ];

        for (const { name, header } of encodings) {
          const headers = header ? { "Accept-Encoding": header } : undefined;
          const result = await fetchWithProxy("https://snappymail.zoo/", { headers });

          expect(result.success, `Request with ${name} should succeed`).toBe(true);

          expect(
            result.body.includes("performance.zoo/shared.js"),
            `Script should be injected with ${name} (Accept-Encoding: ${header || "none"})`,
          ).toBe(true);

          expect(
            result.headers["x-performance-zoo"],
            `x-performance-zoo header should be present with ${name}`,
          ).toBe("injected");
        }
      });
    });
  });
});
