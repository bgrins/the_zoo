import { describe, expect, test } from "vitest";
import { EXTENDED_TEST_TIMEOUT } from "../constants";
import { acceptConsent, BrowserSession, oauthLogin } from "../utils/browser-session";
import { fetchWithProxy } from "../utils/http-client";

// Each test signs in as its own persona so Hydra session/consent state doesn't collide
// with other tests running concurrently.

async function loginToMisc(session: BrowserSession, username: string, password: string) {
  const page = await oauthLogin(session, "https://misc.zoo/oauth/login", username, password);
  expect(new URL(page.finalUrl).hostname).toBe("misc.zoo");
  return page;
}

describe("auth.zoo", () => {
  test("health endpoint reports database connectivity", async () => {
    const result = await fetchWithProxy("https://auth.zoo/api/health", { timeout: 5000 });
    expect(result.httpCode, result.body).toBe(200);
    expect(JSON.parse(result.body)).toMatchObject({ status: "healthy", database: "connected" });
  });

  test("renders Hydra's error redirect", async () => {
    const result = await fetchWithProxy(
      "https://auth.zoo/error?error=invalid_request&error_description=bad+%3Cb%3Eredirect%3C%2Fb%3E",
      { timeout: 5000 },
    );
    expect(result.httpCode).toBe(400);
    expect(result.body).toContain("invalid_request");
    expect(result.body).toContain("bad &lt;b&gt;redirect&lt;/b&gt;");
  });

  test("error page uses the first value of a repeated parameter", async () => {
    const result = await fetchWithProxy(
      "https://auth.zoo/error?error=first_value&error=second_value",
      {
        timeout: 5000,
      },
    );
    expect(result.httpCode, result.body).toBe(400);
    expect(result.body).toContain("<strong>first_value</strong>");
    expect(result.body).not.toContain("second_value");
  });

  test(
    "logout ends the Hydra login session",
    async () => {
      const session = new BrowserSession();
      await loginToMisc(session, "diana", "diana123");

      // Hydra remembers the login, so a new flow completes without a login form
      session.clearCookies("misc.zoo");
      const remembered = await session.request("https://misc.zoo/oauth/login");
      expect(new URL(remembered.finalUrl).hostname).toBe("misc.zoo");

      const logout = await session.request("https://auth.zoo/logout", { method: "POST" });
      expect(logout.finalUrl).toBe("https://auth.zoo/");

      session.clearCookies("misc.zoo");
      const afterLogout = await session.request("https://misc.zoo/oauth/login");
      expect(afterLogout.finalUrl).toContain("https://auth.zoo/login?login_challenge=");
      expect(afterLogout.body).toContain("Login to Zoo");
    },
    EXTENDED_TEST_TIMEOUT,
  );

  test(
    "consent after a skipped login still carries the user's claims",
    async () => {
      const session = new BrowserSession();
      await loginToMisc(session, "charlie", "charlie123");

      // Revoke misc.zoo so the next flow skips login (Hydra session) but asks for consent
      const revoke = await session.request("https://auth.zoo/revoke-app", {
        form: { clientId: "zoo-misc-app" },
      });
      expect(revoke.finalUrl).toBe("https://auth.zoo/dashboard");

      session.clearCookies("misc.zoo");
      const consentPage = await session.request("https://misc.zoo/oauth/login");
      expect(consentPage.finalUrl).toContain("https://auth.zoo/consent?consent_challenge=");
      expect(consentPage.body).toContain("Signed in as <strong>charlie</strong>");

      const misc = await acceptConsent(session, consentPage.body);
      expect(new URL(misc.finalUrl).hostname).toBe("misc.zoo");
      expect(misc.body).toContain('"email": "charlie@snappymail.zoo"');
      expect(misc.body).toContain('"preferred_username": "charlie"');
    },
    EXTENDED_TEST_TIMEOUT,
  );
});
