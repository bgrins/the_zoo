import { exec } from "node:child_process";
import { readFileSync } from "node:fs";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { personas } from "../../scripts/seed-data/personas";
import { getCachedContainerNames } from "../utils/test-cache";
import { getZooDnsIp } from "../utils/dns-config";
import { getZooNetworkName } from "../utils/docker-project";

const execAsync = promisify(exec);

interface Containers {
  postgres?: string;
  redis?: string;
  proxy?: string;
  caddy?: string;
  [key: string]: string | undefined;
}

describe("Database Services Tests", () => {
  let containers: Containers = {};

  beforeAll(async () => {
    containers = await getCachedContainerNames(["postgres", "redis", "proxy", "caddy"]);
  });

  test("PostgreSQL should be accepting connections", async () => {
    const postgresContainer = containers.postgres;
    const readyCmd = `docker exec ${postgresContainer} pg_isready -U postgres -d zoodb`;
    const { stdout: ready } = await execAsync(readyCmd);
    expect(ready, "PostgreSQL not accepting connections").toContain("accepting connections");
  });

  test("Redis should respond to ping", async () => {
    const redisContainer = containers.redis;
    const pingCmd = `docker exec ${redisContainer} redis-cli ping`;
    const { stdout: ping } = await execAsync(pingCmd);
    expect(ping.trim(), "Redis not responding to ping").toBe("PONG");
  });

  // The zoo zone answers any unknown *.zoo name with Caddy's IP, so a dropped alias
  // would still resolve; compare with the service containers' own IPs
  test("database domains resolve to their containers from other containers", async () => {
    const dnsIp = getZooDnsIp();
    const network = getZooNetworkName();
    const services = ["postgres", "redis", "mysql"];
    const names = await getCachedContainerNames([...services, "caddy", "proxy"]);
    const ipOf = async (service: string) =>
      (
        await execAsync(
          `docker inspect -f '{{(index .NetworkSettings.Networks "${network}").IPAddress}}' ${names[service]}`,
        )
      ).stdout.trim();
    const resolve = async (from: string, service: string) =>
      (
        await execAsync(
          `docker exec ${names[from]} nslookup ${service}.zoo ${dnsIp} | grep "Address: " | tail -1`,
        )
      ).stdout
        .trim()
        .replace(/^Address: /, "");

    const expected = Object.fromEntries(
      await Promise.all(services.map(async (s) => [s, await ipOf(s)] as const)),
    );
    expect(Object.values(expected)).not.toContain(await ipOf("caddy"));
    for (const from of ["proxy", "caddy"]) {
      const resolved = Object.fromEntries(
        await Promise.all(services.map(async (s) => [s, await resolve(from, s)] as const)),
      );
      expect(resolved, `resolved from ${from}`).toEqual(expected);
    }
  });

  test("PostgreSQL should be accessible via hostname", async () => {
    const postgresContainer = containers.postgres;

    const psqlCmd = `docker exec -e PGPASSWORD=zoopassword ${postgresContainer} psql -h postgres -U postgres -d zoodb -c "SELECT 'postgres.zoo works' as test" -t -A`;
    const { stdout } = await execAsync(psqlCmd);
    expect(stdout.trim(), "Cannot connect to PostgreSQL via hostname").toBe("postgres.zoo works");
  });

  test("Redis should be accessible via hostname", async () => {
    const redisContainer = containers.redis;

    const redisCmd = `docker exec ${redisContainer} redis-cli -h redis ping`;
    const { stdout } = await execAsync(redisCmd);
    expect(stdout.trim(), "Cannot connect to Redis via hostname").toBe("PONG");
  });

  test("database domains should bypass Caddy", async () => {
    const caddyContainer = containers.caddy;

    // Database domains should not be in Caddy config
    const caddyConfigCmd = `docker exec ${caddyContainer} cat /etc/caddy/Caddyfile | grep -E "(postgres|redis)\\.zoo" | wc -l`;
    const { stdout } = await execAsync(caddyConfigCmd);
    expect(parseInt(stdout.trim()), "Database domains found in Caddy config").toBe(0);
  });

  test("auth database should have every seeded persona", async () => {
    // Other tests and manual use may register more users until postgres restarts
    const { stdout } = await execAsync(
      `docker exec ${containers.postgres} psql -U auth_user -d auth_db -t -A -c "SELECT username FROM users"`,
    );
    expect(stdout.trim().split("\n")).toEqual(
      expect.arrayContaining(personas.map((p) => p.username)),
    );
  });

  test("test users should have bcrypt passwords", async () => {
    const { stdout } = await execAsync(
      `docker exec ${containers.postgres} psql -U auth_user -d auth_db -t -A -c "SELECT username, password_hash FROM users WHERE username IN ('admin', 'alice', 'bob', 'demo') ORDER BY username"`,
    );
    const rows = stdout
      .trim()
      .split("\n")
      .map((line) => line.split("|"));

    expect(rows.map(([username]) => username)).toEqual(["admin", "alice", "bob", "demo"]);
    for (const [username, hash] of rows) {
      expect(hash, `User ${username} has invalid password hash format`).toMatch(/^\$2[ab]\$10\$/);
    }
  });

  test("Hydra has the OAuth clients defined in core/hydra/clients", async () => {
    const defined: string[] = JSON.parse(
      readFileSync(
        new URL("../../core/hydra/clients/default-clients.json", import.meta.url),
        "utf8",
      ),
    ).map((client: { client_id: string }) => client.client_id);

    const { stdout } = await execAsync(
      `docker exec ${containers.postgres} psql -U auth_user -d auth_db -t -A -c "SELECT id FROM hydra_client ORDER BY id"`,
    );
    expect(stdout.trim().split("\n")).toEqual(defined.sort());
  });
});
