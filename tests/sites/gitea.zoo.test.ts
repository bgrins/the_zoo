import { beforeAll, describe, it, expect } from "vitest";
import { execSync } from "node:child_process";
import { fetchWithProxy } from "../utils/http-client";
import { BrowserSession, oauthLogin } from "../utils/browser-session";
import { EXTENDED_TEST_TIMEOUT, ON_DEMAND_FETCH_TIMEOUT, ON_DEMAND_TIMEOUT } from "../constants";
import { warmUp } from "../utils/on-demand";

// Repositories baked into the image by fetch-repos.sh, with their pinned default branch
const BAKED_REPOS = {
  "alice/hello-zoo": "master",
  "alice/express-mirror": "master",
  "bob/zoo-api-client": "master",
  "bob/debug-mirror": "master",
  "charlie/realworld-mirror": "main",
  "charlie/zoo-docker-templates": "master",
  "community/awesome-mirror": "main",
  "community/awesome-zoo": "master",
  "zoo-labs/commander-mirror": "master",
  "zoo-labs/zoo-utilities": "master",
};

describe("gitea.zoo", () => {
  beforeAll(() => warmUp("https://gitea.zoo/", ON_DEMAND_FETCH_TIMEOUT), ON_DEMAND_TIMEOUT);

  it("should be healthy", async () => {
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
    "serves every baked repository with its files and branches",
    {
      timeout: EXTENDED_TEST_TIMEOUT,
    },
    async () => {
      for (const [repo, branch] of Object.entries(BAKED_REPOS)) {
        // The golden DB must agree with the git data: a wrong default branch or a stale
        // is_empty flag renders an empty repo page and a 404/500 branches page.
        const api = await fetchWithProxy(`https://gitea.zoo/api/v1/repos/${repo}`);
        expect(api.httpCode, repo).toBe(200);
        expect(JSON.parse(api.body), repo).toMatchObject({ default_branch: branch, empty: false });

        const home = await fetchWithProxy(`https://gitea.zoo/${repo}`);
        expect(home.httpCode, repo).toBe(200);
        expect(home.body, repo).toContain('id="readme"');

        const branches = await fetchWithProxy(`https://gitea.zoo/${repo}/branches`);
        expect(branches.httpCode, `${repo}/branches`).toBe(200);
      }
    },
  );

  it(
    "should allow login via auth.zoo OAuth",
    async () => {
      // alice's Gitea account is linked to her auth.zoo identity in the golden state
      // (external_login_user), so the callback signs her in instead of asking to link.
      const session = new BrowserSession();
      const landing = await oauthLogin(
        session,
        "https://gitea.zoo/user/oauth2/auth.zoo",
        "alice",
        "alice123",
      );
      expect(landing.finalUrl).toBe("https://gitea.zoo/");
      expect(landing.redirects.some((url) => url.includes("link_account"))).toBe(false);

      const settings = await session.request("https://gitea.zoo/user/settings");
      expect(settings.finalUrl).toBe("https://gitea.zoo/user/settings");
      expect(settings.body).toContain('value="alice"');
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
