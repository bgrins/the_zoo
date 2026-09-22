import { describe, expect, test } from "vitest";
import { EXTENDED_TEST_TIMEOUT, ON_DEMAND_FETCH_TIMEOUT } from "../constants";
import { testUrl, type TestUrlResult, fetchWithProxy } from "../../scripts/lib/http-client";

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

  test.concurrent(
    "performance injection keys off the response Content-Type",
    { timeout: EXTENDED_TEST_TIMEOUT },
    async () => {
      // A POST with a form body used to skip injection because the matcher read request headers
      const post = await fetchWithProxy("https://misc.zoo/", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: "a=b",
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });
      expect(post.httpCode, post.error).toBe(200);
      expect(post.contentType).toContain("text/html");
      expect(post.headers["x-performance-zoo"]).toBe("injected");
      expect(post.body).toContain("performance.zoo/shared.js");

      const json = await fetchWithProxy("https://misc.zoo/api/headers", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });
      expect(json.httpCode, json.error).toBe(200);
      expect(json.contentType).toContain("application/json");
      expect(json.headers["x-performance-zoo"]).toBeUndefined();
    },
  );

  test.concurrent("static sites answer conditional requests", async () => {
    // Caddy's file_server sends validators but no Cache-Control, so browsers revalidate
    const result = await fetchWithProxy("https://performance.zoo/");
    expect(result.httpCode, result.error).toBe(200);
    expect(result.headers).toMatchObject({
      etag: expect.stringMatching(/^"\w+"$/),
      "last-modified": expect.stringMatching(/^\w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2} GMT$/),
    });
    expect(result.headers["cache-control"]).toBeUndefined();

    const revalidated = await fetchWithProxy("https://performance.zoo/", {
      headers: { "If-None-Match": result.headers.etag },
    });
    expect(revalidated.httpCode, revalidated.error).toBe(304);
  });

  test.concurrent("static sites send security headers", async () => {
    // file_server ends the route, so these only apply when set before it. performance.zoo
    // has its own route (with CORS); the other static sites share one snippet.
    const [performance, example] = await Promise.all([
      fetchWithProxy("https://performance.zoo/"),
      fetchWithProxy("https://example.zoo/"),
    ]);
    const security = { "x-content-type-options": "nosniff", "x-frame-options": "SAMEORIGIN" };
    expect(performance.httpCode, performance.error).toBe(200);
    expect(performance.headers).toMatchObject({
      ...security,
      "access-control-allow-origin": "*",
    });
    expect(example.httpCode, example.error).toBe(200);
    expect(example.headers).toMatchObject(security);
  });

  test.concurrent("should serve compressed responses", async () => {
    // Test with explicit Accept-Encoding header to request compression
    const result = await fetchWithProxy("http://misc.zoo/", {
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

  test("apps get the client's X-Forwarded-For with the proxy's IP appended", async () => {
    const result = await fetchWithProxy("http://misc.zoo/api/headers", {
      headers: { "X-Forwarded-For": "192.168.1.100" },
    });

    expect(result.httpCode, result.error).toBe(200);
    // Squid (172.20.250.4) tunnels the request, so Caddy appends the proxy's address
    expect(JSON.parse(result.body).x_forwarded_for).toBe("192.168.1.100, 172.20.250.4");
  });
});
