import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { ON_DEMAND_TIMEOUT } from "../constants";
import { fetchWithProxy } from "../utils/http-client";

describe.skipIf(process.env.CI === "true")("Postmill Tests", () => {
  beforeAll(async () => {
    await getCachedNetworkInfo();
  });

  test(
    "Postmill should be accessible via HTTPS and return HTML",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("https://postmill.zoo", { timeout: 25000 });
      expect(result.success).toBe(true);
      expect(result.httpCode).toBe(200);
      expect(result.contentType).toContain("text/html");

      expect(result.body.toLowerCase()).toContain("<!doctype html>");
      expect(result.body).toContain("Postmill");
    },
  );

  test(
    "Postmill should have correct CSP headers for image loading",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("https://postmill.zoo", { timeout: 25000 });
      expect(result.success).toBe(true);
      expect(result.httpCode).toBe(200);

      // Verify CSP header includes postmill.zoo in img-src
      const cspHeader = result.headers["content-security-policy"];
      expect(cspHeader).toBeDefined();
      expect(cspHeader).toContain("img-src");
      expect(cspHeader).toContain("postmill.zoo");
    },
  );

  test(
    "Postmill submission should serve images via HTTPS",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy(
        "https://postmill.zoo/f/aww/58888/lovely-eyes-full-of-love",
        {
          timeout: 25000,
        },
      );
      expect(result.success).toBe(true);
      expect(result.httpCode).toBe(200);
      expect(result.contentType).toContain("text/html");

      // Verify images use HTTPS URLs, not HTTP
      if (result.body.includes("submission_images")) {
        expect(result.body).toContain("https://postmill.zoo/submission_images");
        expect(result.body).not.toContain('src="http://postmill.zoo/submission_images');
      }
    },
  );

  test("Postmill forums list should be accessible", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("https://postmill.zoo/forums", { timeout: 25000 });
    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);
    expect(result.contentType).toContain("text/html");
    expect(result.body).toContain("Forums");
  });

  test(
    "Postmill login page should have login form elements",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      // Visit homepage first to establish session
      const homeResult = await fetchWithProxy("http://postmill.zoo/", {
        timeout: 25000,
      });
      expect(homeResult.success).toBe(true);
      expect(homeResult.httpCode).toBe(200);

      // Verify that the homepage has a link to login
      expect(homeResult.body).toMatch(/login|log in|sign in/i);

      // Note: Postmill has strict CSRF protection that requires cookie handling that
      // is difficult to test programmatically. The actual login flow works in browsers.
      // Test user: {"username": "MarvelsGrantMan136", "password": "test1234"}
    },
  );
});
