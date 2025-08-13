import { describe, test, expect, beforeAll } from "vitest";
import { config } from "dotenv";
import { fetchWithProxy } from "../utils/http-client";
import { EXTENDED_TEST_TIMEOUT } from "../constants";

describe("OAuth Fresh Instance Tests", () => {
  beforeAll(() => {
    // Load environment variables from .env.fresh
    config({ path: ".env.fresh", override: true });

    // Verify we're using the fresh instance
    expect(process.env.ZOO_PROXY_PORT).toBe("3129");
    expect(process.env.COMPOSE_PROJECT_NAME).toBe("thezoo-fresh");
  });

  test(
    "complete OAuth flow with new user registration",
    async () => {
      // Generate unique user for this test
      const timestamp = Date.now();
      const testUser = {
        username: `testuser${timestamp}`,
        email: `testuser${timestamp}@test.zoo`,
        password: "TestPassword123!",
        name: `Test User ${timestamp}`,
      };

      // Step 1: Register new user at auth.zoo
      const registerResponse = await fetchWithProxy("https://auth.zoo/register", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          username: testUser.username,
          email: testUser.email,
          name: testUser.name,
          password: testUser.password,
          confirmPassword: testUser.password,
        }).toString(),
      });

      // Should redirect to dashboard after successful registration
      expect(registerResponse.httpCode).toBe(302);
      expect(registerResponse.headers.location).toBe("/dashboard");

      // Step 2: Start OAuth flow from oauth-example.zoo
      const oauthStartResponse = await fetchWithProxy("https://oauth-example.zoo/login");

      // Should redirect to Hydra authorization endpoint
      expect(oauthStartResponse.httpCode).toBe(302);
      const authUrl = oauthStartResponse.headers.location;
      expect(authUrl).toContain("/oauth2/auth");
      expect(authUrl).toContain("client_id=zoo-example-app");
      expect(authUrl).toContain("scope=openid");

      // Step 3: Follow redirect to auth.zoo login page
      const loginPageResponse = await fetchWithProxy(authUrl);
      expect(loginPageResponse.httpCode).toBe(302);

      // Extract login challenge from the redirect
      const loginUrl = loginPageResponse.headers.location;
      expect(loginUrl).toContain("/login?login_challenge=");
      const loginChallenge = new URL(loginUrl, "https://auth.zoo").searchParams.get(
        "login_challenge",
      );
      expect(loginChallenge).toBeTruthy();

      if (!loginChallenge) {
        throw new Error("Login challenge not found");
      }

      // Step 4: Submit login credentials
      const loginResponse = await fetchWithProxy("https://auth.zoo/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          challenge: loginChallenge,
          username: testUser.username,
          password: testUser.password,
        }).toString(),
      });

      // Should redirect to consent page
      expect(loginResponse.httpCode).toBe(302);
      const consentUrl = loginResponse.headers.location;
      expect(consentUrl).toContain("/oauth2/auth");

      // Step 5: Follow to consent page
      const consentPageResponse = await fetchWithProxy(consentUrl);
      expect(consentPageResponse.httpCode).toBe(302);

      // Extract consent challenge
      const consentRedirectUrl = consentPageResponse.headers.location;
      expect(consentRedirectUrl).toContain("/consent?consent_challenge=");
      const consentChallenge = new URL(consentRedirectUrl, "https://auth.zoo").searchParams.get(
        "consent_challenge",
      );
      expect(consentChallenge).toBeTruthy();

      if (!consentChallenge) {
        throw new Error("Consent challenge not found");
      }

      // Step 6: Grant consent
      const consentResponse = await fetchWithProxy("https://auth.zoo/consent", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          challenge: consentChallenge,
          submit: "accept",
          scopes: "openid,profile,email,offline",
        }).toString(),
      });

      // Should redirect back to oauth-example.zoo with authorization code
      expect(consentResponse.httpCode).toBe(302);
      const callbackUrl = consentResponse.headers.location;
      expect(callbackUrl).toContain("oauth-example.zoo/callback");
      expect(callbackUrl).toContain("code=");

      // Step 7: Follow final redirect to complete flow
      const finalResponse = await fetchWithProxy(callbackUrl);
      expect(finalResponse.httpCode).toBe(302);
      expect(finalResponse.headers.location).toBe("/");

      // Step 8: Verify user is logged in at oauth-example.zoo
      const profileResponse = await fetchWithProxy("https://oauth-example.zoo/profile");
      expect(profileResponse.httpCode).toBe(200);
      expect(profileResponse.body).toContain(testUser.username);
      expect(profileResponse.body).toContain(testUser.email);
    },
    EXTENDED_TEST_TIMEOUT,
  );

  test("user can revoke OAuth access", async () => {
    // This test assumes the previous test has run
    // In a fresh instance, we have a clean slate to test revocation

    // First, check connected apps at auth.zoo
    const dashboardResponse = await fetchWithProxy("https://auth.zoo/dashboard");
    expect(dashboardResponse.httpCode).toBe(200);
    expect(dashboardResponse.body).toContain("Connected Applications");
    expect(dashboardResponse.body).toContain("zoo-example-app");

    // Extract the revoke form data
    const clientIdMatch = dashboardResponse.body.match(/name="clientId" value="([^"]+)"/);
    expect(clientIdMatch).toBeTruthy();

    if (!clientIdMatch) {
      throw new Error("Client ID not found in dashboard");
    }

    const clientId = clientIdMatch[1];

    // Revoke access
    const revokeResponse = await fetchWithProxy("https://auth.zoo/revoke-app", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        clientId: clientId,
      }).toString(),
    });

    expect(revokeResponse.httpCode).toBe(302);
    expect(revokeResponse.headers.location).toBe("/dashboard");

    // Verify app is no longer in connected apps
    const updatedDashboardResponse = await fetchWithProxy("https://auth.zoo/dashboard");
    expect(updatedDashboardResponse.httpCode).toBe(200);
    expect(updatedDashboardResponse.body).toContain("No connected applications yet");
  });
});
