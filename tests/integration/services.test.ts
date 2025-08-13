import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import {
  getCachedContainerNames,
  getCachedNetworkInfo,
  preloadCaches,
} from "../utils/test-cache.js";

const execAsync = promisify(exec);

type CoreServices = Record<string, string>;

describe("Services Tests", () => {
  let coreServices: CoreServices = {};

  beforeAll(async () => {
    await preloadCaches();
    const serviceNames = ["caddy", "dns", "proxy", "postgres", "redis", "stalwart"];
    coreServices = await getCachedContainerNames(serviceNames);
  });

  test("core services should be running", async () => {
    const names = Object.values(coreServices).filter(Boolean);
    const cmd = `docker ps --format "{{.Names}}:{{.Status}}" | grep -E "(${names.join("|")})"`;

    const { stdout } = await execAsync(cmd);
    const statuses = Object.fromEntries(
      stdout
        .trim()
        .split("\n")
        .map((line) => {
          const [name, ...statusParts] = line.split(":");
          return [name, statusParts.join(":")];
        }),
    );

    Object.entries(statuses).forEach(([name, status]) => {
      expect(status, `Service ${name} is not running. Status: ${status}`).toContain("Up");
    });
  });

  test("postgres databases should be created", async () => {
    const pgContainer = coreServices.postgres;
    if (!pgContainer) return;

    const cmd = `docker exec ${pgContainer} psql -U postgres -c "\\l" | grep -E "_db" | wc -l`;
    const { stdout } = await execAsync(cmd);
    const dbCount = parseInt(stdout.trim());

    expect(dbCount, `Expected more than 5 databases but found only ${dbCount}`).toBeGreaterThan(5);
  });

  test("redis should be accessible", async () => {
    const redisContainer = coreServices.redis;
    if (!redisContainer) return;

    const cmd = `docker exec ${redisContainer} redis-cli ping`;
    const { stdout } = await execAsync(cmd);

    expect(stdout.trim(), `Redis ping failed. Response: ${stdout.trim()}`).toBe("PONG");
  });

  test("network configuration should be valid", async () => {
    const networkInfo = await getCachedNetworkInfo();
    expect(networkInfo.subnet, `Invalid subnet format: ${networkInfo.subnet}`).toMatch(
      /^\d+\.\d+\.\d+\.\d+\/\d+$/,
    );
  });
});
