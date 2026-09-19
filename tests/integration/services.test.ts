import { exec } from "node:child_process";
import { readFileSync } from "node:fs";
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
    const serviceNames = ["postgres", "redis"];
    coreServices = await getCachedContainerNames(serviceNames);
  });

  test("postgres databases should be created", async () => {
    // One database per create_db_for_site call in the init script
    const initScript = readFileSync(
      new URL("../../core/postgres/init-databases.sh", import.meta.url),
      "utf8",
    );
    const expected = [...initScript.matchAll(/^create_db_for_site "([^"]+)"/gm)]
      .map((m) => `${m[1]}_db`)
      .sort();

    const { stdout } = await execAsync(
      `docker exec ${coreServices.postgres} psql -U postgres -t -A -c "SELECT datname FROM pg_database WHERE datname LIKE '%\\_db' ORDER BY datname"`,
    );
    expect(stdout.trim().split("\n")).toEqual(expected);
  });

  test("redis should be accessible", async () => {
    const cmd = `docker exec ${coreServices.redis} redis-cli ping`;
    const { stdout } = await execAsync(cmd);

    expect(stdout.trim(), `Redis ping failed. Response: ${stdout.trim()}`).toBe("PONG");
  });

  test("network configuration should be valid", async () => {
    const networkInfo = await getCachedNetworkInfo();
    expect(networkInfo.subnet, `Invalid subnet format: ${networkInfo.subnet}`).toMatch(
      /^\d+\.\d+\.\d+\.\d+\/\d+$/,
    );
  });

  test("apps can fetch other apps via HTTPS without certificate errors", async () => {
    // Start misc-zoo container (it has wget and SSL_CERT_FILE configured)
    await execAsync("docker compose --profile on-demand up -d misc-zoo --wait --wait-timeout 30");

    // Use misc-zoo to fetch home.zoo via HTTPS - this tests the CA trust chain
    const { stdout, stderr } = await execAsync(
      "docker compose exec misc-zoo wget -q -O- --timeout=10 https://home.zoo/",
    );

    // Should get HTML content without certificate errors
    expect(stdout).toContain("<!DOCTYPE html>");
    expect(stderr).not.toContain("certificate");
    expect(stderr).not.toContain("SSL");
  });
});
