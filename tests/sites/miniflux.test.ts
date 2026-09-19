import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { EXTENDED_TEST_TIMEOUT, ON_DEMAND_TIMEOUT } from "../constants";
import { BrowserSession, oauthLogin } from "../utils/browser-session";
import { fetchWithProxy } from "../utils/http-client";

describe("Miniflux Tests", () => {
  beforeAll(async () => {
    await getCachedNetworkInfo();
  });

  test(
    "Miniflux should be accessible and return HTML",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("https://miniflux.zoo", { timeout: 25000 });
      expect(result.success).toBe(true);
      expect(result.httpCode).toBe(200);
      expect(result.contentType).toContain("text/html");

      expect(result.body.toLowerCase()).toContain("<!doctype html>");
      expect(result.body).toContain("Miniflux");
    },
  );

  test(
    "Caddy should convert CSP meta tag to report-only mode",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("https://miniflux.zoo", { timeout: 25000 });
      expect(result.success).toBe(true);
      expect(result.httpCode).toBe(200);

      // Miniflux embeds CSP in a meta tag. Caddy should convert it to report-only
      // so the performance.zoo script injection doesn't get blocked
      expect(result.body).toContain('http-equiv="Content-Security-Policy-Report-Only"');
      expect(result.body).not.toContain('http-equiv="Content-Security-Policy"');
    },
  );

  test(
    "auth.zoo OAuth login lands in the seeded account",
    { timeout: EXTENDED_TEST_TIMEOUT },
    async () => {
      // Requires the OIDC issuer to match Hydra's and the seeded user's openid_connect_id
      // to be linked; otherwise Miniflux tries to create a duplicate "frank" and fails.
      const session = new BrowserSession();
      const page = await oauthLogin(
        session,
        "https://miniflux.zoo/oauth2/oidc/redirect",
        "frank",
        "frank123",
      );
      expect(new URL(page.finalUrl).hostname).toBe("miniflux.zoo");
      expect(page.httpCode).toBe(200);

      const me = await session.request("https://miniflux.zoo/settings");
      expect(me.finalUrl).toBe("https://miniflux.zoo/settings");
      expect(me.body).toContain('value="frank"');
    },
  );

  test("Performance Zoo script should be injected", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("https://miniflux.zoo", { timeout: 25000 });
    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);

    // Verify the performance script is injected
    expect(result.body).toContain("https://performance.zoo/shared.js");
  });
});
