import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { fetchWithProxy } from "../../scripts/lib/http-client";

describe("Misc API Tests", () => {
  beforeAll(async () => {
    // Ensure network info is cached for other tests
    await getCachedNetworkInfo();
  });

  test("whoami endpoint should return client info", async () => {
    const result = await fetchWithProxy("http://misc.zoo/api/whoami");

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
});
