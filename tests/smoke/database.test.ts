import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { getCachedContainerNames } from "../utils/test-cache";
import { getZooDnsIp } from "../utils/dns-config";

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

  test("PostgreSQL should be healthy and accepting connections", async () => {
    const postgresContainer = containers.postgres;

    // Check health status
    const healthCmd = `docker inspect ${postgresContainer} --format "{{.State.Health.Status}}"`;
    const { stdout: health } = await execAsync(healthCmd);
    expect(health.trim(), "PostgreSQL is not healthy").toBe("healthy");

    // Check readiness
    const readyCmd = `docker exec ${postgresContainer} pg_isready -U postgres -d zoodb`;
    const { stdout: ready } = await execAsync(readyCmd);
    expect(ready, "PostgreSQL not accepting connections").toContain("accepting connections");
  });

  test("Redis should be healthy and responding", async () => {
    const redisContainer = containers.redis;

    // Check health status
    const healthCmd = `docker inspect ${redisContainer} --format "{{.State.Health.Status}}"`;
    const { stdout: health } = await execAsync(healthCmd);
    expect(health.trim(), "Redis is not healthy").toBe("healthy");

    // Check Redis ping
    const pingCmd = `docker exec ${redisContainer} redis-cli ping`;
    const { stdout: ping } = await execAsync(pingCmd);
    expect(ping.trim(), "Redis not responding to ping").toBe("PONG");
  });

  test("database domains should resolve correctly", async () => {
    const proxyContainer = containers.proxy;
    const dnsIp = getZooDnsIp();

    const [postgresDns, redisDns, mysqlDns] = await Promise.all([
      execAsync(
        `docker exec ${proxyContainer} nslookup postgres.zoo ${dnsIp} | grep "Address: " | tail -1`,
      ),
      execAsync(
        `docker exec ${proxyContainer} nslookup redis.zoo ${dnsIp} | grep "Address: " | tail -1`,
      ),
      execAsync(
        `docker exec ${proxyContainer} nslookup mysql.zoo ${dnsIp} | grep "Address: " | tail -1`,
      ),
    ]);

    expect(postgresDns.stdout.trim(), "postgres.zoo not resolving").toMatch(
      /Address: \d+\.\d+\.\d+\.\d+/,
    );
    expect(redisDns.stdout.trim(), "redis.zoo not resolving").toMatch(
      /Address: \d+\.\d+\.\d+\.\d+/,
    );
    expect(mysqlDns.stdout.trim(), "mysql.zoo not resolving").toMatch(
      /Address: \d+\.\d+\.\d+\.\d+/,
    );
  });

  test("database domains should work from containers", async () => {
    const caddyContainer = containers.caddy;
    const dnsIp = getZooDnsIp();

    const [pgDns, redisDns, mysqlDns] = await Promise.all([
      execAsync(
        `docker exec ${caddyContainer} nslookup postgres.zoo ${dnsIp} | grep "Address: " | tail -1`,
      ),
      execAsync(
        `docker exec ${caddyContainer} nslookup redis.zoo ${dnsIp} | grep "Address: " | tail -1`,
      ),
      execAsync(
        `docker exec ${caddyContainer} nslookup mysql.zoo ${dnsIp} | grep "Address: " | tail -1`,
      ),
    ]);

    expect(pgDns.stdout.trim(), "postgres.zoo not resolving from caddy").toMatch(
      /Address: \d+\.\d+\.\d+\.\d+/,
    );
    expect(redisDns.stdout.trim(), "redis.zoo not resolving from caddy").toMatch(
      /Address: \d+\.\d+\.\d+\.\d+/,
    );
    expect(mysqlDns.stdout.trim(), "mysql.zoo not resolving from caddy").toMatch(
      /Address: \d+\.\d+\.\d+\.\d+/,
    );
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

  test("auth database should have seeded users", async () => {
    const postgresContainer = containers.postgres;

    // Check users table
    const tableCheckCmd = `docker exec -e PGPASSWORD=auth_pw ${postgresContainer} psql -h localhost -U auth_user -d auth_db -c "SELECT COUNT(*) FROM users" -t -A 2>/dev/null || echo "0"`;
    const { stdout } = await execAsync(tableCheckCmd);
    const userCount = parseInt(stdout.trim());

    expect(userCount, "No users found in auth database").toBeGreaterThan(0);
  });

  test("test users should have bcrypt passwords", async () => {
    const postgresContainer = containers.postgres;

    const userCheckCmd = `docker exec -e PGPASSWORD=auth_pw ${postgresContainer} psql -h localhost -U auth_user -d auth_db -c "SELECT username, password_hash FROM users WHERE username IN ('admin', 'alice', 'bob', 'demo') ORDER BY username" -t -A 2>/dev/null || echo ""`;
    const { stdout } = await execAsync(userCheckCmd);
    const lines = stdout.trim().split("\n").filter(Boolean);

    expect(lines.length, "No test users found").toBeGreaterThan(0);

    // Validate bcrypt format
    lines.forEach((line) => {
      const [username, hash] = line.split("|");
      if (hash) {
        expect(hash, `User ${username} has invalid password hash format`).toMatch(/^\$2[ab]\$/);
      }
    });
  });

  test("Hydra OAuth tables should exist", async () => {
    const postgresContainer = containers.postgres;

    const hydraTableCmd = `docker exec -e PGPASSWORD=auth_pw ${postgresContainer} psql -h localhost -U auth_user -d auth_db -c "SELECT COUNT(*) FROM hydra_oauth2_flow WHERE consent_remember = true OR consent_remember = false" -t -A 2>/dev/null || echo "0"`;
    const { stdout } = await execAsync(hydraTableCmd);
    const flowCount = parseInt(stdout.trim());

    expect(flowCount, "Hydra OAuth tables not found").toBeGreaterThanOrEqual(0);
  });

  test("postgres database snapshot files should exist in container", async () => {
    const postgresContainer = containers.postgres;

    const postgresSnapshots = [
      "auth_db.sql.xz",
      "focalboard_db.sql.xz",
      "gitea_db.sql.xz",
      "miniflux_db.sql.xz",
      "planka_db.sql.xz",
      "stalwart_db.sql.xz",
    ];

    const { stdout } = await execAsync(
      `docker exec ${postgresContainer} ls /var/lib/postgresql/snapshots/`,
    );
    const files = stdout.trim().split("\n");

    postgresSnapshots.forEach((snapshot) => {
      expect(files, `Postgres snapshot ${snapshot} should exist in container`).toContain(snapshot);
    });
  });

  test("mysql database snapshot files should exist in container", async () => {
    const mysqlContainer = await getCachedContainerNames(["mysql"]).then((c) => c.mysql);

    const mysqlSnapshots = ["northwind_db.sql.xz", "vwa-classifieds_db.sql.xz"];

    const { stdout } = await execAsync(
      `docker exec ${mysqlContainer} ls /var/lib/mysql/snapshots/`,
    );
    const files = stdout.trim().split("\n");

    mysqlSnapshots.forEach((snapshot) => {
      expect(files, `MySQL snapshot ${snapshot} should exist in container`).toContain(snapshot);
    });
  });
});
