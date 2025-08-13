import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { fetchWithProxy } from "../utils/http-client";

describe("Utils API Tests", () => {
  beforeAll(async () => {
    // Ensure network info is cached for other tests
    await getCachedNetworkInfo();
  });

  test("whoami endpoint should return client info", async () => {
    const result = await fetchWithProxy("http://utils.zoo/api/whoami");

    if (!result.success) {
      throw new Error(`Failed to fetch whoami endpoint: ${result.error}`);
    }

    let response;
    try {
      response = JSON.parse(result.body);
    } catch (_e) {
      throw new Error(`Failed to parse whoami response: ${result.body}`);
    }

    // Check response structure
    expect(response, "whoami response missing required fields").toHaveProperty("ip");
    expect(response, "whoami response missing user_agent").toHaveProperty("user_agent");
    expect(response, "whoami response missing headers").toHaveProperty("headers");

    // Verify IP is properly forwarded (should now be the real client IP, not Docker network)
    // The IP should be a valid IPv4 address
    const ipPattern = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;
    expect(response.ip, `IP ${response.ip} is not a valid IPv4 address`).toMatch(ipPattern);

    // Verify proxy headers
    expect(response.headers, "Missing X-Forwarded-For header").toHaveProperty("X-Forwarded-For");
    expect(response.headers, "Missing Via header indicating proxy chain").toHaveProperty("Via");
  });

  test("API and HTML whoami endpoints should show same IP", async () => {
    // Get API response
    const apiResult = await fetchWithProxy("http://utils.zoo/api/whoami");
    if (!apiResult.success) {
      throw new Error(`API request failed: ${apiResult.error}`);
    }
    const apiResponse = JSON.parse(apiResult.body);

    // Get HTML response
    const htmlResult = await fetchWithProxy("http://utils.zoo/whoami");
    if (!htmlResult.success) {
      throw new Error(`HTML request failed: ${htmlResult.error}`);
    }
    const htmlOutput = htmlResult.body;

    // Extract IP from HTML
    const ipMatch = htmlOutput.match(/<th>Your IP Address<\/th>\s*<td>([^<]+)<\/td>/);
    expect(ipMatch, `Could not extract IP from HTML response`).not.toBeNull();
    const htmlIp = ipMatch?.[1].trim();

    expect(htmlIp, `HTML IP (${htmlIp}) doesn't match API IP (${apiResponse.ip})`).toBe(
      apiResponse.ip,
    );
  });

  test("X-Forwarded-For header should include real client IP", async () => {
    // Try to inject fake IP via X-Forwarded-For
    const result = await fetchWithProxy("http://utils.zoo/api/whoami", {
      headers: { "X-Forwarded-For": "1.2.3.4, 5.6.7.8" },
    });

    if (!result.success) {
      throw new Error(`Request failed: ${result.error}`);
    }

    const response = JSON.parse(result.body);

    // The X-Forwarded-For header should contain the real client IP even if injected headers are present
    expect(response.headers["X-Forwarded-For"], "Missing X-Forwarded-For header").toBeDefined();

    // The header should contain multiple IPs in a chain
    const forwardedFor = response.headers["X-Forwarded-For"];
    const ips = forwardedFor.split(",").map((ip: string) => ip.trim());

    // Should have at least 3 IPs: injected ones + real client IP + proxy IP
    expect(
      ips.length,
      `Expected at least 3 IPs in chain, got ${ips.length}`,
    ).toBeGreaterThanOrEqual(3);

    // The real client IP should be in the chain (not just the injected ones)
    const hasRealIP = ips.some(
      (ip: string) =>
        ip !== "1.2.3.4" && ip !== "5.6.7.8" && ip.match(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/),
    );
    expect(hasRealIP, `X-Forwarded-For should contain real client IP, got: ${forwardedFor}`).toBe(
      true,
    );
  });

  test("UUID endpoint should generate valid UUIDs", async () => {
    const result = await fetchWithProxy("http://utils.zoo/api/uuid");

    if (!result.success) {
      throw new Error(`Failed to fetch UUID endpoint: ${result.error}`);
    }

    let response;
    try {
      response = JSON.parse(result.body);
    } catch (_e) {
      throw new Error(`Failed to parse UUID response: ${result.body}`);
    }

    expect(response, "UUID response missing uuid field").toHaveProperty("uuid");

    // Validate UUID v4 format
    const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    expect(response.uuid, `Invalid UUID format: ${response.uuid}`).toMatch(uuidPattern);
  });
});
