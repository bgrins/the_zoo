import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { describe, expect, test } from "vitest";
import { EXTENDED_TEST_TIMEOUT } from "../constants";
import { acceptConsent, BrowserSession, formValue, oauthLogin } from "../utils/browser-session";
import { getCachedContainerNames } from "../utils/test-cache";
import { fetchWithProxy } from "../../scripts/lib/http-client";

const execFileAsync = promisify(execFile);

// Each test signs in as its own persona so Hydra session/consent state doesn't collide
// with other tests running concurrently.

async function loginToMisc(session: BrowserSession, username: string, password: string) {
  const page = await oauthLogin(session, "https://misc.zoo/oauth/login", username, password);
  expect(new URL(page.finalUrl).hostname).toBe("misc.zoo");
  return page;
}

/** Messages in the persona's inbox with `subject` in their subject */
async function inboxCount(username: string, password: string, subject: string): Promise<number> {
  const { stalwart } = await getCachedContainerNames(["stalwart"]);
  const { stdout } = await execFileAsync("docker", [
    ...["exec", stalwart, "curl", "-sf", "-u", `${username}@snappymail.zoo:${password}`],
    ...["imap://localhost/INBOX", "-X", `SEARCH SUBJECT "${subject}"`],
  ]);
  // "* SEARCH 3 7"
  return stdout.trim().split(/\s+/).length - 2;
}

describe("auth.zoo", () => {
  test("health endpoint reports database connectivity", async () => {
    const result = await fetchWithProxy("https://auth.zoo/api/health", { timeout: 5000 });
    expect(result.httpCode, result.body).toBe(200);
    expect(JSON.parse(result.body)).toMatchObject({ status: "healthy", database: "connected" });
  });

  test.each(["/", "/register", "/explore"])(
    "%s has a language and one main landmark, and links over https",
    async (path) => {
      const result = await fetchWithProxy(`https://auth.zoo${path}`, { timeout: 5000 });
      expect(result.httpCode, result.body).toBe(200);
      expect(result.body).toContain('<html lang="en">');
      expect(result.body.match(/<main\b/g)).toHaveLength(1);
      expect(result.body).not.toMatch(/href="http:\/\//);
    },
  );

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
    "signing in on auth.zoo's own page signs in to the apps",
    async () => {
      const session = new BrowserSession();
      const signIn = await session.request("https://auth.zoo/direct-login", {
        form: { username: "demo", password: "demo123" },
      });
      expect(signIn.finalUrl).toBe("https://auth.zoo/dashboard");

      const misc = await session.request("https://misc.zoo/oauth/login");
      expect(misc.finalUrl).toBe("https://misc.zoo/");
      expect(misc.body).toContain('"preferred_username": "demo"');
    },
    EXTENDED_TEST_TIMEOUT,
  );

  test(
    "a first-party app reconnects after a revoke without a consent screen",
    async () => {
      const session = new BrowserSession();
      const loginPage = await session.request("https://misc.zoo/oauth/login");
      const challenge = formValue(loginPage.body, "challenge");
      expect(challenge, loginPage.finalUrl).toBeDefined();
      // auth.zoo accepts the consent step itself, so submitting the login lands on misc.zoo
      const first = await session.request("https://auth.zoo/login", {
        form: { challenge: challenge as string, username: "charlie", password: "charlie123" },
      });
      expect(first.finalUrl).toBe("https://misc.zoo/");

      const revoke = await session.request("https://auth.zoo/revoke-app", {
        form: { clientId: "zoo-misc-app" },
      });
      expect(revoke.finalUrl).toBe("https://auth.zoo/dashboard");
      expect(revoke.body).not.toContain('value="zoo-misc-app"');

      // The Hydra session skips the login, and the new grant must still carry the claims
      session.clearCookies("misc.zoo");
      const misc = await session.request("https://misc.zoo/oauth/login");
      expect(misc.finalUrl).toBe("https://misc.zoo/");
      expect(misc.body).toContain('"email": "charlie@snappymail.zoo"');
      expect(misc.body).toContain('"preferred_username": "charlie"');

      const dashboard = await session.request("https://auth.zoo/dashboard");
      expect(dashboard.body.match(/name="clientId" value="zoo-misc-app"/g)).toHaveLength(1);
    },
    EXTENDED_TEST_TIMEOUT,
  );

  test(
    "a third-party app asks for consent, and only it emails that it's connected",
    async () => {
      const [username, password] = ["bob", "bob123"];
      // An earlier run's consent would skip the screen
      const earlier = new BrowserSession();
      await earlier.request("https://auth.zoo/direct-login", { form: { username, password } });
      await earlier.request("https://auth.zoo/revoke-app", {
        form: { clientId: "misc-third-party" },
      });
      const connected = (app = "") => inboxCount(username, password, `New app connected: ${app}`);
      const before = { all: await connected(), thirdParty: await connected("Third-Party Demo") };

      await loginToMisc(new BrowserSession(), username, password);

      const session = new BrowserSession();
      const loginPage = await session.request("https://misc.zoo/oauth/third-party/login");
      const challenge = formValue(loginPage.body, "challenge");
      expect(challenge, loginPage.finalUrl).toBeDefined();
      const consent = await session.request("https://auth.zoo/login", {
        form: { challenge: challenge as string, username, password },
      });
      expect(consent.finalUrl).toMatch(/^https:\/\/auth\.zoo\/consent\?consent_challenge=/);
      expect(consent.body).toContain("<strong>Third-Party Demo (misc.zoo)</strong> is requesting");

      const misc = await acceptConsent(session, consent.body);
      expect(misc.finalUrl).toBe("https://misc.zoo/");
      expect(misc.body).toContain('"preferred_username": "bob"');

      // Mail arrives in order, so any from the first-party sign-in would be in by now
      await expect
        .poll(() => connected("Third-Party Demo"), { timeout: 10_000 })
        .toBe(before.thirdParty + 1);
      expect(await connected()).toBe(before.all + 1);
    },
    EXTENDED_TEST_TIMEOUT,
  );
});
