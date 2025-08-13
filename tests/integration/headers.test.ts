import { describe, expect, test } from "vitest";
import { testUrl, type TestUrlResult, fetchWithProxy } from "../utils/http-client";

describe("HTTP Headers Tests", () => {
  test.concurrent("HTML responses should have performance header", async () => {
    const result = await testUrl("http://example.zoo/", {
      expectHeaders: ["x-performance-zoo"],
    });

    expect(
      result.allOk,
      `Header test failed for ${result.url}: HTTP ${result.httpCode}, headers: ${JSON.stringify(result.headers)}`,
    ).toBe(true);
    expect(
      result.headers["x-performance-zoo"],
      `Missing or invalid x-performance-zoo header: ${result.headers["x-performance-zoo"]}`,
    ).toContain("injected");
  });

  test.concurrent("static sites should have caching headers", async () => {
    // Test performance.zoo which should have proper caching
    const result = await testUrl("http://performance.zoo/", {
      expectHeaders: ["etag", "last-modified", "cache-control"],
    });

    const hasCachingHeaders =
      result.headers.etag || result.headers["last-modified"] || result.headers["cache-control"];

    expect(
      hasCachingHeaders,
      `${result.url} missing caching headers. Found: ${JSON.stringify(result.headers)}`,
    ).toBeTruthy();
  });

  test.concurrent("should serve compressed responses", async () => {
    // Test with explicit Accept-Encoding header to request compression
    const result = await fetchWithProxy("http://search.zoo/", {
      headers: { "Accept-Encoding": "gzip, deflate" },
    });

    expect(result.success, `Failed to fetch ${result.url}`).toBe(true);
    expect(result.httpCode).toBe(200);
    expect(
      result.headers["content-encoding"],
      `Expected gzip encoding but got: ${result.headers["content-encoding"]}`,
    ).toContain("gzip");
  });

  test.concurrent("API responses should have correct content types", async () => {
    const tests = [
      testUrl("http://search-api.zoo/health", {
        expectContentType: "application/json",
      }),
      testUrl(`http://performance.zoo/shared.js?t=${Date.now()}`, {
        expectContentType: "javascript",
      }),
    ];

    const results = await Promise.all(tests);
    results.forEach((result: TestUrlResult) => {
      expect(
        result.contentTypeOk,
        `${result.url} has wrong content type: ${result.contentType} (expected ${result.expectContentType})`,
      ).toBe(true);
    });
  });

  test.concurrent("should forward client IP through proxy", async () => {
    // Test that X-Forwarded-For header is being added by the proxy
    // We'll test a dynamic app that can echo headers back
    const result = await testUrl("http://utils.zoo/api/headers", {
      fetchBody: true,
    });

    expect(result.success, `Failed to reach ${result.url}`).toBe(true);
    expect(result.httpCode).toBe(200);

    // Parse the JSON response body to check headers received by the backend
    const responseData = JSON.parse(result.body);

    // The backend should receive X-Forwarded-For header from the proxy
    expect(
      responseData.x_forwarded_for || responseData.headers?.["X-Forwarded-For"],
      "X-Forwarded-For header not received by backend application",
    ).toBeDefined();

    // The header should contain a valid IP address chain
    const forwardedFor = responseData.x_forwarded_for || responseData.headers?.["X-Forwarded-For"];
    expect(forwardedFor).toMatch(/\d+\.\d+\.\d+\.\d+/);
  });

  test("show detailed header forwarding info", async () => {
    const result = await fetchWithProxy("http://utils.zoo/api/headers", {
      headers: {
        "X-Forwarded-For": "192.168.1.100", // Simulate a client IP
      },
    });

    expect(result.success).toBe(true);
    const data = JSON.parse(result.body);

    // console.log("=== Header Forwarding Debug Info ===");
    // console.log("X-Forwarded-For:", data.x_forwarded_for);
    // console.log("X-Real-IP:", data.x_real_ip);
    // console.log("Remote Addr:", data.remote_addr);
    // console.log("\nAll Headers:");
    // Object.entries(data.headers).forEach(([key, value]) => {
    //   if (
    //     key.toLowerCase().includes("forward") ||
    //     key.toLowerCase().includes("real") ||
    //     key.toLowerCase().includes("proxy") ||
    //     key.toLowerCase() === "host"
    //   ) {
    //     console.log(`  ${key}: ${value}`);
    //   }
    // });

    // The X-Forwarded-For should NOT be just the proxy IP (172.20.250.4)
    // It should include the actual client IP from outside the Docker network
    expect(data.x_forwarded_for).not.toBe("172.20.250.4");

    // The X-Forwarded-For should contain the client IP followed by the proxy IP
    expect(data.x_forwarded_for).toBe("192.168.1.100, 172.20.250.4");

    // The X-Forwarded-For should contain IPs in the correct order
    const forwardedIps = data.x_forwarded_for
      ? data.x_forwarded_for.split(",").map((ip: string) => ip.trim())
      : [];
    expect(forwardedIps[0]).toBe("192.168.1.100"); // Original client
    expect(forwardedIps[1]).toBe("172.20.250.4"); // Squid proxy
  });
});
