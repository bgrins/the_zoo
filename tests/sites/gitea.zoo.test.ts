import { describe, it, expect } from "vitest";
import { execSync } from "node:child_process";
import { fetchWithProxy } from "../utils/http-client";
import { ON_DEMAND_TIMEOUT, EXTENDED_TEST_TIMEOUT } from "../constants";

describe("gitea.zoo", () => {
  it("should be healthy", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const response = await fetchWithProxy("http://gitea.zoo");
    expect(response.httpCode).toBe(200);
    expect(response.body).toContain("Gitea");
  });

  it("should have OAuth2 authentication configured", async () => {
    const response = await fetchWithProxy("http://gitea.zoo/user/login");

    // Check that the OAuth2 login option is present
    expect(response.body).toContain("auth.zoo");
    expect(response.body).toContain("Sign in with auth.zoo");
  });

  it("should have OpenID discovery endpoint accessible", async () => {
    const response = await fetchWithProxy("http://auth.zoo/.well-known/openid-configuration");

    expect(response.httpCode).toBe(200);
    const config = JSON.parse(response.body);

    // Verify OpenID configuration
    expect(config.issuer).toBe("https://auth.zoo");
    expect(config.authorization_endpoint).toBe("https://auth.zoo/oauth2/auth");
    expect(config.token_endpoint).toBe("https://auth.zoo/oauth2/token");
    expect(config.userinfo_endpoint).toBe("https://auth.zoo/userinfo");
  });

  it(
    "should allow login via auth.zoo OAuth",
    async () => {
      // Cookie jar to maintain session across redirects (keyed by domain)
      const cookieJar: Record<string, string[]> = {};

      function collectCookies(url: string, response: Awaited<ReturnType<typeof fetchWithProxy>>) {
        const domain = new URL(url, "http://auth.zoo").hostname;
        if (!cookieJar[domain]) cookieJar[domain] = [];
        for (const c of response.cookies || []) {
          // Replace existing cookie with same name
          cookieJar[domain] = cookieJar[domain].filter(
            (existing) => !existing.startsWith(`${c.name}=`),
          );
          cookieJar[domain].push(`${c.name}=${c.value}`);
        }
      }

      function cookieHeader(url: string): Record<string, string> {
        const domain = new URL(url, "http://auth.zoo").hostname;
        const cookies = cookieJar[domain];
        return cookies?.length ? { Cookie: cookies.join("; ") } : {};
      }

      function expectRedirect(response: Awaited<ReturnType<typeof fetchWithProxy>>) {
        expect(response.httpCode).toBeGreaterThanOrEqual(300);
        expect(response.httpCode).toBeLessThan(400);
        expect(response.headers.location).toBeTruthy();
      }

      const manual = { redirect: "manual" as const };

      // Step 1: Start OAuth flow from Gitea
      const oauthStartResponse = await fetchWithProxy(
        "http://gitea.zoo/user/oauth2/auth.zoo",
        manual,
      );
      expectRedirect(oauthStartResponse);
      collectCookies("http://gitea.zoo", oauthStartResponse);
      const authUrl = oauthStartResponse.headers.location;
      expect(authUrl).toContain("/oauth2/auth");
      expect(authUrl).toContain("client_id=gitea");

      // Step 2: Follow redirect to Hydra → auth.zoo login page
      const loginPageResponse = await fetchWithProxy(authUrl, {
        ...manual,
        headers: cookieHeader(authUrl),
      });
      expectRedirect(loginPageResponse);
      collectCookies(authUrl, loginPageResponse);
      const loginUrl = loginPageResponse.headers.location;
      expect(loginUrl).toContain("/login?login_challenge=");
      const loginChallenge = new URL(loginUrl, "http://auth.zoo").searchParams.get(
        "login_challenge",
      );
      expect(loginChallenge).toBeTruthy();
      if (!loginChallenge) throw new Error("missing login_challenge");

      // Step 3: Submit login credentials
      const loginResponse = await fetchWithProxy("http://auth.zoo/login", {
        ...manual,
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          ...cookieHeader("http://auth.zoo"),
        },
        body: new URLSearchParams({
          challenge: loginChallenge,
          username: "alice",
          password: "alice123",
        }).toString(),
      });
      expectRedirect(loginResponse);
      collectCookies("http://auth.zoo", loginResponse);
      const postLoginUrl = loginResponse.headers.location;
      expect(postLoginUrl).toContain("/oauth2/auth");

      // Step 4: Follow to consent page (needs CSRF cookie from Hydra)
      const consentPageResponse = await fetchWithProxy(postLoginUrl, {
        ...manual,
        headers: cookieHeader(postLoginUrl),
      });
      expectRedirect(consentPageResponse);
      collectCookies(postLoginUrl, consentPageResponse);
      const consentRedirectUrl = consentPageResponse.headers.location;
      expect(consentRedirectUrl).toContain("/consent?consent_challenge=");
      const consentChallenge = new URL(consentRedirectUrl, "http://auth.zoo").searchParams.get(
        "consent_challenge",
      );
      expect(consentChallenge).toBeTruthy();
      if (!consentChallenge) throw new Error("missing consent_challenge");

      // Step 5: Grant consent
      const consentResponse = await fetchWithProxy("http://auth.zoo/consent", {
        ...manual,
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          ...cookieHeader("http://auth.zoo"),
        },
        body: new URLSearchParams({
          challenge: consentChallenge,
          submit: "accept",
          scopes: "openid,profile,email,offline",
        }).toString(),
      });
      expectRedirect(consentResponse);
      collectCookies("http://auth.zoo", consentResponse);

      // Step 5b: Follow Hydra consent_verifier redirect → callback with code
      const consentVerifierUrl = consentResponse.headers.location;
      const finalRedirect = await fetchWithProxy(consentVerifierUrl, {
        ...manual,
        headers: cookieHeader(consentVerifierUrl),
      });
      expectRedirect(finalRedirect);
      const callbackUrl = finalRedirect.headers.location;
      expect(callbackUrl).toContain("gitea.zoo/user/oauth2/auth.zoo/callback");
      expect(callbackUrl).toContain("code=");

      // Step 6: Follow callback — Gitea should link the OAuth identity
      // to the existing alice account (via external_login_user) and redirect
      const callbackResponse = await fetchWithProxy(callbackUrl, {
        ...manual,
        headers: cookieHeader(callbackUrl),
      });
      expectRedirect(callbackResponse);
      // Should NOT redirect to /user/link_account (that means linking failed)
      expect(callbackResponse.headers.location).not.toContain("link_account");

      // Should set a session cookie indicating successful login
      const sessionCookie = callbackResponse.cookies?.find(
        (c) => c.name === "i_like_gitea" || c.name === "_csrf",
      );
      expect(sessionCookie).toBeTruthy();
    },
    EXTENDED_TEST_TIMEOUT,
  );

  it("should use Redis for caching", async () => {
    // Access a repo page to trigger cache population
    const response = await fetchWithProxy("http://gitea.zoo/alice/hello-zoo");
    expect(response.httpCode).toBe(200);

    // Verify Gitea's MacaronCache key exists in Redis
    const exists = execSync("docker compose exec -T redis redis-cli EXISTS MacaronCache", {
      encoding: "utf8",
    }).trim();
    expect(exists).toBe("1");
  });
});
