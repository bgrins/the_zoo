import { readFileSync } from "node:fs";
import { parse } from "dotenv";
import { beforeAll, describe, expect, test } from "vitest";
import { PROXY_PORT, PROXY_URL } from "../../scripts/lib/proxy";
import { EXTENDED_TEST_TIMEOUT } from "../constants";
import { BrowserSession, oauthLogin } from "../utils/browser-session";

describe("OAuth on a fresh (unseeded) instance", () => {
  beforeAll(() => {
    // Users registered on the main instance would break the tests that expect only the seeded ones
    if (PROXY_PORT !== Number(parse(readFileSync(".env.fresh")).ZOO_PROXY_PORT)) {
      throw new Error(
        `${PROXY_URL} is not the fresh instance's proxy; run these with npm run test:fresh`,
      );
    }
  });

  test(
    "a newly registered user can sign in to misc.zoo and revoke it",
    async () => {
      const session = new BrowserSession();
      const id = Date.now();
      const user = {
        username: `testuser${id}`,
        email: `testuser${id}@test.zoo`,
        name: `Test User ${id}`,
        password: "TestPassword123!",
      };

      const registered = await session.request("https://auth.zoo/register", { form: user });
      expect(registered.finalUrl).toBe("https://auth.zoo/dashboard");

      // Registration signs in to auth.zoo only; Hydra still asks for an interactive login
      const misc = await oauthLogin(
        session,
        "https://misc.zoo/oauth/login",
        user.username,
        user.password,
      );
      expect(new URL(misc.finalUrl).hostname).toBe("misc.zoo");
      expect(misc.body).toContain(`"preferred_username": "${user.username}"`);
      expect(misc.body).toContain(`"email": "${user.email}"`);

      const dashboard = await session.request("https://auth.zoo/dashboard");
      expect(dashboard.body).toContain('name="clientId" value="zoo-misc-app"');

      const revoked = await session.request("https://auth.zoo/revoke-app", {
        form: { clientId: "zoo-misc-app" },
      });
      expect(revoked.finalUrl).toBe("https://auth.zoo/dashboard");
      expect(revoked.body).toContain("No applications connected yet.");
    },
    EXTENDED_TEST_TIMEOUT,
  );
});
