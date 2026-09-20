import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { COLD_START_TIMEOUT, ON_DEMAND_FETCH_TIMEOUT, ON_DEMAND_TIMEOUT } from "../constants";
import { BrowserSession, formValue } from "../utils/browser-session";
import { warmUp } from "../utils/on-demand";
import { fetchWithProxy } from "../../scripts/lib/http-client";

describe.skipIf(process.env.CI === "true")("Postmill Tests", () => {
  beforeAll(async () => {
    await getCachedNetworkInfo();
    await warmUp("https://postmill.zoo/");
  }, COLD_START_TIMEOUT);

  test(
    "Postmill should be accessible via HTTPS and return HTML",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("https://postmill.zoo", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });
      expect(result.success).toBe(true);
      expect(result.httpCode).toBe(200);
      expect(result.contentType).toContain("text/html");

      expect(result.body.toLowerCase()).toContain("<!doctype html>");
      expect(result.body).toContain("Postmill");
    },
  );

  test("Caddy should have stripped CSP headers", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("https://postmill.zoo", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });
    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);

    // Verify CSP header includes postmill.zoo in img-src
    const cspHeader = result.headers["content-security-policy"];
    expect(cspHeader).not.toBeDefined();
  });

  test(
    "Postmill submission should serve images via HTTPS",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy(
        "https://postmill.zoo/f/aww/58888/lovely-eyes-full-of-love",
        {
          timeout: ON_DEMAND_FETCH_TIMEOUT,
        },
      );
      expect(result.success).toBe(true);
      expect(result.httpCode).toBe(200);
      expect(result.contentType).toContain("text/html");

      expect(result.body).toContain(
        'src="https://postmill.zoo/submission_images/2623920aaf83a733d7341a6a622c3e6055825cf97ddf0438b2c0700eb2a5bee3.jpg"',
      );
      expect(result.body).not.toContain('src="http://postmill.zoo/submission_images');
    },
  );

  test("Postmill forums list should be accessible", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("https://postmill.zoo/forums", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });
    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);
    expect(result.contentType).toContain("text/html");
    expect(result.body).toContain("Forums");
  });

  test(
    "Postmill login page should have login form elements",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      // /login redirects to ?_cookie_check=… and answers 403 without the cookie it just set
      const page = await new BrowserSession().request("https://postmill.zoo/login", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });
      expect(page.httpCode, page.error).toBe(200);
      expect(page.finalUrl).toMatch(/^https:\/\/postmill\.zoo\/login\?_cookie_check=\d+$/);

      const form = page.body.match(/<form action="\/login_check" method="POST"[\s\S]*?<\/form>/);
      expect(form, "login form").not.toBeNull();
      const inputs = [...(form?.[0] ?? "").matchAll(/<input\b[^>]*\bname="(\w+)"/g)];
      expect(inputs.map((input) => input[1])).toEqual([
        "_csrf_token",
        "_username",
        "_password",
        "_remember_me",
      ]);
      expect(formValue(page.body, "_csrf_token")).toMatch(/^[\w.-]{40,}$/);
      expect(form?.[0]).toContain('<button type="submit" class="button">Log in</button>');
    },
  );
});
