import { exec } from "node:child_process";
import { statSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import { personas } from "../../scripts/seed-data/personas";
import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo, getCachedContainerNames } from "../utils/test-cache";
import { ON_DEMAND_FETCH_TIMEOUT, ON_DEMAND_TIMEOUT } from "../constants";
import { serviceHealth } from "../utils/containers";
import { fetchWithProxy } from "../../scripts/lib/http-client";

const execAsync = promisify(exec);
const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..");

describe("Focalboard Tests", () => {
  let containers: Record<string, string> = {};

  beforeAll(async () => {
    // Ensure network info is cached for other tests
    await getCachedNetworkInfo();
    // Get dynamic container names
    containers = await getCachedContainerNames(["postgres"]);
  });

  test(
    "Focalboard should be accessible and return HTML",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://focalboard.zoo", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });

      if (!result.success) {
        throw new Error(`Failed to access Focalboard: ${result.error}`);
      }

      expect(result.httpCode).toBe(200);
    },
  );

  test("Focalboard should return proper HTML content", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://focalboard.zoo", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });

    if (!result.success) {
      throw new Error(`Failed to fetch Focalboard content: ${result.error}`);
    }

    // Check for expected HTML structure (case-insensitive for DOCTYPE)
    expect(result.body.toLowerCase()).toContain("<!doctype html>");
    expect(result.body).toContain("<html");
    expect(result.body).toContain("</html>");

    expect(result.body).toContain("<title>Focalboard</title>");
    expect(result.body).toContain('<div id="focalboard-app"></div>');
  });

  test("Focalboard should have proper headers", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://focalboard.zoo", {
      method: "HEAD",
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });

    if (!result.success) {
      throw new Error(`Failed to fetch Focalboard headers: ${result.error}`);
    }

    // Check for expected headers
    expect(result.contentType).toContain("text/html");
    // Focalboard sends no Server header; Caddy adds Via
    expect(result.headers.server).toBeUndefined();
    expect(result.headers.via).toBe("1.1 Caddy");
    expect(result.httpCode).toBe(200);
  });

  test("Focalboard container should be healthy", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    // Caddy holds the first request until the container's healthcheck passes
    const result = await fetchWithProxy("http://focalboard.zoo", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });
    expect(result.httpCode, result.error).toBe(200);
    expect(serviceHealth("focalboard-zoo")).toBe("healthy");
  });

  test(
    "a board made from a template shows the template's images",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      // user1 is the test account; the board stays until the next reset, since deleting a
      // board with files fails in Focalboard 7.11 (it queries a "fileinfo" table)
      const login = await fetchWithProxy("https://focalboard.zoo/api/v2/login", {
        method: "POST",
        timeout: ON_DEMAND_FETCH_TIMEOUT,
        headers: { "Content-Type": "application/json", "X-Requested-With": "XMLHttpRequest" },
        body: JSON.stringify({ type: "normal", username: "user1", password: "password" }),
      });
      expect(login.httpCode, login.body).toBe(200);
      const headers = {
        Authorization: `Bearer ${JSON.parse(login.body).token}`,
        "X-Requested-With": "XMLHttpRequest",
      };
      const api = async (path: string, method = "GET") => {
        const result = await fetchWithProxy(`https://focalboard.zoo/api/v2${path}`, {
          method,
          headers,
          timeout: ON_DEMAND_FETCH_TIMEOUT,
        });
        expect(result.httpCode, `${method} ${path}`).toBe(200);
        return result;
      };
      type Block = { type: string; fields: { fileId?: string } };
      const images = (blocks: Block[]) =>
        blocks.filter((b) => b.type === "image").map((b) => String(b.fields.fileId));
      try {
        const templates = JSON.parse((await api("/teams/0/templates")).body);
        // Titles carry the trailing space of the built-in templates
        const roadmap = templates.find((t: { title: string }) => t.title.trim() === "Roadmap");
        // The response lists the template's blocks; the copy's own name the copied files
        const copy = JSON.parse(
          (await api(`/boards/${roadmap.id}/duplicate?asTemplate=false&toTeam=0`, "POST")).body,
        );
        const board = copy.boards[0].id;
        const golden = images(copy.blocks).map(
          (file) =>
            statSync(
              resolve(root, "sites/apps/focalboard.zoo/data-golden/files/0", roadmap.id, file),
            ).size,
        );
        const copied = images(JSON.parse((await api(`/boards/${board}/blocks?all=true`)).body));
        const sizes: number[] = [];
        for (const file of copied) {
          sizes.push((await api(`/files/teams/0/${board}/${file}`)).bytes.length);
        }
        const bySize = (a: number, b: number) => a - b;
        expect(golden).toHaveLength(3);
        expect(sizes.sort(bySize)).toEqual(golden.sort(bySize));
      } finally {
        await fetchWithProxy("https://focalboard.zoo/api/v2/logout", {
          method: "POST",
          headers,
          timeout: ON_DEMAND_FETCH_TIMEOUT,
        });
      }
    },
  );

  test("Focalboard database should have the seeded users", async () => {
    const { stdout } = await execAsync(
      `docker exec ${containers.postgres} psql -U focalboard_user -d focalboard_db -t -A -c "SELECT username FROM users"`,
    );
    expect(stdout.trim().split("\n")).toEqual(
      expect.arrayContaining(personas.map((p) => p.username)),
    );
  });
});
