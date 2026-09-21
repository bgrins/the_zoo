import { exec } from "node:child_process";
import { promisify } from "node:util";
import { personas } from "../../scripts/seed-data/personas";
import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo, getCachedContainerNames } from "../utils/test-cache";
import { COLD_START_TIMEOUT, ON_DEMAND_FETCH_TIMEOUT, ON_DEMAND_TIMEOUT } from "../constants";
import { warmUp } from "../utils/on-demand";
import { serviceHealth } from "../utils/containers";
import { fetchWithProxy } from "../../scripts/lib/http-client";

const execAsync = promisify(exec);

describe("Mattermost Tests", () => {
  let containers: Record<string, string> = {};

  beforeAll(async () => {
    await getCachedNetworkInfo();
    containers = await getCachedContainerNames(["postgres"]);
    await warmUp("https://mattermost.zoo/");
  }, COLD_START_TIMEOUT);

  test(
    "Mattermost should be accessible and return HTML",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://mattermost.zoo", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });

      if (!result.success) {
        throw new Error(`Failed to access Mattermost: ${result.error}`);
      }

      expect(result.httpCode).toBe(200);
      expect(result.contentType).toContain("text/html");
    },
  );

  test("Mattermost should return proper HTML content", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://mattermost.zoo", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });

    if (!result.success) {
      throw new Error(`Failed to fetch Mattermost content: ${result.error}`);
    }

    expect(result.body.toLowerCase()).toContain("<!doctype html>");
    expect(result.body).toContain("<html");
    expect(result.body).toContain("</html>");

    // Check for Mattermost-specific content
    expect(result.body.toLowerCase()).toMatch(/mattermost/i);
  });

  test("Performance Zoo script should be injected", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://mattermost.zoo", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });
    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);

    // Verify the performance script is injected
    expect(result.body).toContain("https://performance.zoo/shared.js");
  });

  test(
    "developer mode, test commands and internet-only features are off",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      // Signed-in users get the full client config; the session is logged out again
      const login = await fetchWithProxy("https://mattermost.zoo/api/v4/users/login", {
        method: "POST",
        timeout: ON_DEMAND_FETCH_TIMEOUT,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ login_id: "alice", password: "alice123" }),
      });
      expect(login.httpCode, login.body).toBe(200);
      const auth = { Authorization: `Bearer ${login.headers.token}` };
      try {
        const config = await fetchWithProxy(
          "https://mattermost.zoo/api/v4/config/client?format=old",
          { headers: auth, timeout: ON_DEMAND_FETCH_TIMEOUT },
        );
        expect(JSON.parse(config.body)).toMatchObject({
          EnableDeveloper: "false",
          EnableTesting: "false",
          EnableGifPicker: "false",
        });
      } finally {
        await fetchWithProxy("https://mattermost.zoo/api/v4/users/logout", {
          method: "POST",
          headers: auth,
          timeout: ON_DEMAND_FETCH_TIMEOUT,
        });
      }
    },
  );

  test("Mattermost container should be healthy", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    // Caddy holds the first request until the container's healthcheck passes
    const result = await fetchWithProxy("http://mattermost.zoo", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });
    expect(result.httpCode, result.error).toBe(200);
    expect(serviceHealth("mattermost")).toBe("healthy");
  });

  test(
    "the seeded channel's posts and the personas' names are served",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const login = await fetchWithProxy("https://mattermost.zoo/api/v4/users/login", {
        method: "POST",
        timeout: ON_DEMAND_FETCH_TIMEOUT,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ login_id: "alice", password: "alice123" }),
      });
      expect(login.httpCode, login.body).toBe(200);
      const headers = { Authorization: `Bearer ${login.headers.token}` };
      const api = async (path: string) => {
        const result = await fetchWithProxy(`https://mattermost.zoo/api/v4${path}`, {
          headers,
          timeout: ON_DEMAND_FETCH_TIMEOUT,
        });
        expect(result.httpCode, path).toBe(200);
        return JSON.parse(result.body);
      };
      try {
        const channel = await api("/teams/name/zoo/channels/name/engineering");
        const { posts } = await api(`/channels/${channel.id}/posts?per_page=200`);
        const all = (
          Object.values(posts) as { type: string; message: string; create_at: number }[]
        ).sort((a, b) => a.create_at - b.create_at);
        // Its eight members joined when blake.sullivan created it, before anyone posted
        expect(all.slice(0, 8).map((p) => p.type)).toEqual(Array(8).fill("system_join_channel"));
        const messages = all.filter((p) => p.type === "");
        expect(messages).toHaveLength(10);
        expect([messages[0].message, new Date(messages[0].create_at).toISOString()]).toEqual([
          "I filed zoo-labs/zoo-utilities#1: `generateToken` uses `Math.random`. Treat any token it has issued as guessable.",
          "2026-09-01T09:20:00.000Z",
        ]);

        const bob = await api("/users/username/bob");
        expect([bob.first_name, bob.last_name]).toEqual(["Robert 'Bob'", "Smith"]);
      } finally {
        await fetchWithProxy("https://mattermost.zoo/api/v4/users/logout", {
          method: "POST",
          headers,
          timeout: ON_DEMAND_FETCH_TIMEOUT,
        });
      }
    },
  );

  test(
    "a persona's Threads view lists the threads they're in, unread since their last reply",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const login = await fetchWithProxy("https://mattermost.zoo/api/v4/users/login", {
        method: "POST",
        timeout: ON_DEMAND_FETCH_TIMEOUT,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ login_id: "alice", password: "alice123" }),
      });
      expect(login.httpCode, login.body).toBe(200);
      const headers = { Authorization: `Bearer ${login.headers.token}` };
      try {
        const team = await fetchWithProxy("https://mattermost.zoo/api/v4/teams/name/zoo", {
          headers,
          timeout: ON_DEMAND_FETCH_TIMEOUT,
        });
        const result = await fetchWithProxy(
          `https://mattermost.zoo/api/v4/users/me/teams/${JSON.parse(team.body).id}/threads`,
          { headers, timeout: ON_DEMAND_FETCH_TIMEOUT },
        );
        expect(result.httpCode, result.body).toBe(200);
        const { threads } = JSON.parse(result.body);
        expect(
          threads
            .map(
              (t: { post: { message: string }; reply_count: number; unread_replies: number }) => [
                t.post.message.split(/[.:] /)[0],
                t.reply_count,
                t.unread_replies,
              ],
            )
            .sort(),
        ).toEqual([
          ["Demo day is Friday, September 18 at 15:00 UTC", 3, 2],
          ["I filed zoo-labs/zoo-utilities#1", 2, 1],
          ["The token fix is up for review", 1, 1],
        ]);
      } finally {
        await fetchWithProxy("https://mattermost.zoo/api/v4/users/logout", {
          method: "POST",
          headers,
          timeout: ON_DEMAND_FETCH_TIMEOUT,
        });
      }
    },
  );

  test("Mattermost database should have the seeded users", async () => {
    const { stdout } = await execAsync(
      `docker exec ${containers.postgres} psql -U mattermost_user -d mattermost_db -t -A -c "SELECT username FROM users WHERE deleteat = 0"`,
    );
    expect(stdout.trim().split("\n")).toEqual(
      expect.arrayContaining(personas.map((p) => p.username)),
    );
  });

  test("Mattermost API should return server info", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://mattermost.zoo/api/v4/system/ping", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });

    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);
    expect(result.contentType).toContain("application/json");
  });
});
