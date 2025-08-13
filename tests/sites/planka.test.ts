import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { ON_DEMAND_TIMEOUT } from "../constants";
import { fetchWithProxy } from "../utils/http-client";

describe("Planka Tests", () => {
  beforeAll(async () => {
    // Ensure network info is cached for other tests
    await getCachedNetworkInfo();
  });

  test("Planka should be accessible and return HTML", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("https://planka.zoo", { timeout: 25000 });
    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);
    expect(result.contentType).toContain("text/html");

    // Check for Planka app structure (HTML5 doctype can be lowercase)
    expect(result.body.toLowerCase()).toContain("<!doctype html>");
    expect(result.body).toContain("<title>Planka</title>");
  });

  test("Planka API config should be accessible", async () => {
    const result = await fetchWithProxy("https://planka.zoo/api/config", { timeout: 10000 });
    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);
    expect(result.contentType).toContain("application/json");

    const json = JSON.parse(result.body);
    expect(json).toHaveProperty("item");
    expect(json.item).toHaveProperty("oidc");
    // Verify OIDC is configured correctly
    expect(json.item.oidc.authorizationUrl).toContain("http://auth.zoo");
    expect(json.item.oidc.isEnforced).toBe(false);
  });

  test("Planka should have login endpoint", async () => {
    const result = await fetchWithProxy("https://planka.zoo/api/access-tokens", {
      timeout: 10000,
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        emailOrUsername: "invalid@test.com",
        password: "invalid",
      }),
    });

    // Should return 401 for invalid credentials
    expect(result.httpCode).toBe(401);
    expect(result.contentType).toContain("application/json");
  });
});
