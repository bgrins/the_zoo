import { beforeAll, describe, it, expect } from "vitest";
import { fetchWithProxy } from "../../scripts/lib/http-client";
import { gitea } from "../../scripts/seed-data/content";
import { BrowserSession, oauthLogin } from "../utils/browser-session";
import { COLD_START_TIMEOUT, EXTENDED_TEST_TIMEOUT } from "../constants";
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
  beforeAll(() => warmUp("https://gitea.zoo/"), COLD_START_TIMEOUT);

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
    "serves the seeded issues, pull requests and review",
    { timeout: EXTENDED_TEST_TIMEOUT },
    async () => {
      const api = async (path: string) => {
        const result = await fetchWithProxy(`https://gitea.zoo/api/v1${path}`);
        expect(result.httpCode, path).toBe(200);
        return JSON.parse(result.body);
      };
      const summary = (i: { number: number; title: string; state: string }) =>
        JSON.stringify([i.number, i.title, i.state]);
      for (const repo of new Set(gitea.issues.map((i) => i.repo))) {
        const seeded = gitea.issues.filter((i) => i.repo === repo);
        for (const [kind, path] of [
          ["issues", `/repos/${repo}/issues?state=all&type=issues&limit=50`],
          ["pulls", `/repos/${repo}/pulls?state=all&limit=50`],
        ]) {
          expect((await api(path)).map(summary).sort(), `${repo} ${kind}`).toEqual(
            seeded
              .filter((i) => Boolean(i.pull) === (kind === "pulls"))
              .map((i) => summary({ ...i, state: i.closed ? "closed" : "open" }))
              .sort(),
          );
        }
      }

      const issue = await api("/repos/zoo-labs/zoo-utilities/issues/1");
      expect({
        title: issue.title,
        by: issue.user.login,
        state: issue.state,
        labels: issue.labels.map((l: { name: string }) => l.name),
        milestone: issue.milestone.title,
        assignees: issue.assignees.map((u: { login: string }) => u.login),
        comments: issue.comments,
        created: issue.created_at,
      }).toEqual({
        title: "generateToken uses Math.random, which is not secure",
        by: "grace",
        state: "open",
        labels: ["bug", "security"],
        milestone: "v1.3.0",
        assignees: ["alice"],
        comments: 2,
        created: "2026-09-01T09:12:00Z",
      });

      // The pull requests' branches and heads come from git-golden
      const pull = await api("/repos/zoo-labs/zoo-utilities/pulls/4");
      expect([pull.state, pull.merged, pull.mergeable, pull.head.ref, pull.base.ref]).toEqual([
        "open",
        false,
        true,
        "alice/secure-tokens",
        "master",
      ]);
      const files = await api("/repos/zoo-labs/zoo-utilities/pulls/4/files");
      expect(files.map((f: { filename: string }) => f.filename)).toEqual(["lib/auth.js"]);
      const reviews = await api("/repos/zoo-labs/zoo-utilities/pulls/4/reviews");
      expect(
        reviews.map((r: { user: { login: string }; state: string; comments_count: number }) => [
          r.user.login,
          r.state,
          r.comments_count,
        ]),
      ).toEqual([["grace", "COMMENT", 1]]);
      const closed = await api("/repos/bob/zoo-api-client/pulls/3");
      expect([closed.state, closed.merged, closed.head.ref]).toEqual(["closed", false, "esbuild"]);
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
});
