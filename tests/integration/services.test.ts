import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { COLD_START_TIMEOUT } from "../constants";
import { warmUp } from "../utils/on-demand";
import { getCachedContainerNames, getCachedNetworkInfo, preloadCaches } from "../utils/test-cache";

const execAsync = promisify(exec);

describe("Services Tests", () => {
  let postgres = "";

  beforeAll(async () => {
    await preloadCaches();
    postgres = (await getCachedContainerNames(["postgres"])).postgres;
    // Caddy starts misc-zoo (it has wget and SSL_CERT_FILE configured) on first request
    await warmUp("https://misc.zoo/");
  }, COLD_START_TIMEOUT);

  test("postgres databases should be created", async () => {
    // One per create_db_for_site call in core/postgres/init-external-databases.sh and
    // init-databases.sh
    const { stdout } = await execAsync(
      `docker exec ${postgres} psql -U postgres -t -A -c "SELECT datname FROM pg_database WHERE datname LIKE '%\\_db' ORDER BY datname"`,
    );
    expect(stdout.trim().split("\n")).toEqual([
      "auth_db",
      "focalboard_db",
      "gitea_db",
      "mattermost_db",
      "miniflux_db",
      "postmill_db",
      "stalwart_db",
    ]);
  });

  test("network configuration should be valid", async () => {
    const networkInfo = await getCachedNetworkInfo();
    expect(networkInfo.subnet, `Invalid subnet format: ${networkInfo.subnet}`).toMatch(
      /^\d+\.\d+\.\d+\.\d+\/\d+$/,
    );
  });

  test("apps can fetch other apps via HTTPS without certificate errors", async () => {
    // Fetching home.zoo over HTTPS from inside a container tests the CA trust chain
    const { stdout, stderr } = await execAsync(
      "docker compose exec -T misc-zoo wget -q -O- --timeout=5 https://home.zoo/",
    );

    expect(stdout).toContain("<!DOCTYPE html>");
    expect(stderr).not.toContain("certificate");
    expect(stderr).not.toContain("SSL");
  });
});
