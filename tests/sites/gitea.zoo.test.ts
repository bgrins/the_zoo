import { describe, it, expect } from "vitest";
import { fetchWithProxy } from "../utils/http-client";
import { ON_DEMAND_TIMEOUT } from "../constants";

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
    expect(config.issuer).toBe("http://auth.zoo");
    expect(config.authorization_endpoint).toBe("http://auth.zoo/oauth2/auth");
    expect(config.token_endpoint).toBe("http://auth.zoo/oauth2/token");
    expect(config.userinfo_endpoint).toBe("http://auth.zoo/userinfo");
  });
});
