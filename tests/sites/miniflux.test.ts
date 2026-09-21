import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { EXTENDED_TEST_TIMEOUT, ON_DEMAND_FETCH_TIMEOUT, ON_DEMAND_TIMEOUT } from "../constants";
import { BrowserSession, oauthLogin } from "../utils/browser-session";
import { fetchWithProxy } from "../../scripts/lib/http-client";

describe("Miniflux Tests", () => {
  beforeAll(async () => {
    await getCachedNetworkInfo();
  });

  test(
    "Miniflux should be accessible and return HTML",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("https://miniflux.zoo", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });
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
      const result = await fetchWithProxy("https://miniflux.zoo", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });
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

  test(
    "alice's subscriptions hold the entries fetched from gitea.zoo",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const api = async (path: string) => {
        const result = await fetchWithProxy(`https://miniflux.zoo/v1${path}`, {
          timeout: ON_DEMAND_FETCH_TIMEOUT,
          headers: { Authorization: `Basic ${Buffer.from("alice:alice123").toString("base64")}` },
        });
        expect(result.httpCode, path).toBe(200);
        return JSON.parse(result.body);
      };
      const feeds: { id: number; feed_url: string; category: { title: string } }[] =
        await api("/feeds");
      const { unreads, reads } = await api("/feeds/counters");
      // Polling is off, so each feed keeps the entries the golden state fetched
      expect(
        Object.fromEntries(
          feeds.map((f) => [f.feed_url, [f.category.title, unreads[f.id] ?? 0, reads[f.id] ?? 0]]),
        ),
      ).toEqual({
        "https://gitea.zoo/zoo-labs/zoo-utilities.rss": ["Zoo Labs", 15, 0],
        "https://gitea.zoo/zoo-labs.rss": ["Zoo Labs", 16, 0],
        "https://gitea.zoo/alice/hello-zoo.rss": ["My projects", 8, 0],
      });
      const { entries } = await api("/entries?order=published_at&direction=desc&limit=1");
      expect([entries[0].published_at, entries[0].url]).toEqual([
        "2026-09-11T13:01:00Z",
        "https://gitea.zoo/alice/hello-zoo/issues/3#issuecomment-47",
      ]);
    },
  );

  test("Performance Zoo script should be injected", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("https://miniflux.zoo", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });
    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);

    // Verify the performance script is injected
    expect(result.body).toContain("https://performance.zoo/shared.js");
  });
});
