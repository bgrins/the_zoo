import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { execSync } from "node:child_process";
import { fetchWithProxy } from "../../scripts/lib/http-client";
import { personas } from "../../scripts/seed-data/personas";
import { isServiceAvailable } from "../utils/available";
import { getCachedContainerName } from "../utils/test-cache";
import {
  EXTENDED_TEST_TIMEOUT,
  EXTRA_EXTENDED_TEST_TIMEOUT,
  ON_DEMAND_FETCH_TIMEOUT,
} from "../constants";

// Helper to execute commands and return output
function exec(command: string): string {
  try {
    return execSync(command, { encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }).trim();
  } catch (error: any) {
    // For some commands we expect errors (e.g., checking if table doesn't exist)
    if (error.stderr) {
      throw new Error(error.stderr.toString());
    }
    throw new Error(`Command failed: ${command}\n${error.message}`);
  }
}

// Helper to execute commands that might fail (returns output or error)
function execMayFail(command: string): { output?: string; error?: string } {
  try {
    return {
      output: execSync(command, { encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }).trim(),
    };
  } catch (error: any) {
    return { error: error.stderr?.toString() || error.message };
  }
}

// Logs since `since`, so a check can't match the previous start's lines. The margin covers
// clock skew between the host and the Docker VM.
function logsSince(service: string, since: Date): string {
  return exec(
    `docker compose logs ${service} --since ${new Date(since.getTime() - 2000).toISOString()}`,
  );
}

// Helper to wait for container to be healthy
async function waitForHealthy(service: string, maxAttempts = 30): Promise<void> {
  for (let i = 0; i < maxAttempts; i++) {
    try {
      const result = execMayFail(`docker compose ps ${service} --format "{{.Health}}"`);
      if (result.output?.trim() === "healthy") {
        return;
      }
    } catch {
      // Container might not exist yet
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  throw new Error(`${service} did not become healthy within ${maxAttempts} seconds`);
}

function startedAt(service: string): string {
  return exec(`docker inspect --format '{{.State.StartedAt}}' $(docker compose ps -q ${service})`);
}

// A restore makes the services that follow the database (core/follow-restore.sh) stop within
// a few seconds; their restart policy starts them again
async function waitForRestart(service: string, before: string): Promise<void> {
  for (let i = 0; i < 60 && startedAt(service) === before; i++) {
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  expect(startedAt(service), `${service} restarted`).not.toBe(before);
}

// This test is skipped by default because it:
// 1. Takes a long time to run (~100 seconds)
// 2. Modifies database state
// 3. Requires restarting containers
//
// To run this test explicitly:
// npm run test:infrastructure
//
// Or run directly:
// RUN_INFRASTRUCTURE_TESTS=1 npm run test tests/infrastructure/database-reset.test.ts

const shouldRun = process.env.RUN_INFRASTRUCTURE_TESTS === "1";

describe.skipIf(!shouldRun)("Database Golden State Restoration", { retry: 0 }, () => {
  let pgContainer: string;
  let mysqlContainer: string;

  // Ensure containers are up before tests
  beforeAll(async () => {
    console.log("Ensuring database containers are running...");
    exec("docker compose up -d postgres mysql");
    await waitForHealthy("postgres");
    await waitForHealthy("mysql");

    // Get container names
    pgContainer = await getCachedContainerName("postgres");
    mysqlContainer = await getCachedContainerName("mysql");
    console.log(`Using containers: ${pgContainer}, ${mysqlContainer}`);
  }, EXTRA_EXTENDED_TEST_TIMEOUT);

  describe("PostgreSQL", () => {
    it(
      "should restore from golden state on container creation",
      async () => {
        // Recreate container
        exec("docker compose rm -sfv postgres");
        exec("docker compose up -d postgres");

        // Check logs for restore message
        await waitForHealthy("postgres");
        const logs = exec("docker compose logs postgres --tail 50");
        expect(logs).toContain("Restoring PostgreSQL database from golden state");
        expect(logs).toMatch(/Database restore completed in \d+\.\d{3} seconds/);
      },
      EXTENDED_TEST_TIMEOUT,
    );

    it(
      "should restore from golden state on container restart",
      async () => {
        // Create test data
        exec(`docker exec ${pgContainer} psql -U postgres -c "CREATE DATABASE test_db_reset;"`);
        exec(
          `docker exec ${pgContainer} psql -U auth_user -d auth_db -c "CREATE TABLE test_table (id serial PRIMARY KEY);"`,
        );

        // Verify test data exists
        const databases = exec(
          `docker exec ${pgContainer} psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datname='test_db_reset';"`,
        );
        expect(databases).toContain("test_db_reset");

        // Restart container
        const restartedAt = new Date();
        exec("docker compose restart postgres");
        await waitForHealthy("postgres");

        // Check logs for restore message
        const logs = logsSince("postgres", restartedAt);
        expect(logs).toContain("Restoring PostgreSQL database from golden state");
        expect(logs).toMatch(/Database restore completed in \d+\.\d{3} seconds/);

        // Verify test data is gone
        const databasesAfter = exec(
          `docker exec ${pgContainer} psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datname='test_db_reset';"`,
        );
        expect(databasesAfter).not.toContain("test_db_reset");

        // Verify test table is gone
        const tableResult = execMayFail(
          `docker exec ${pgContainer} psql -U auth_user -d auth_db -c "SELECT * FROM test_table;"`,
        );
        expect(tableResult.error).toContain('relation "test_table" does not exist');
      },
      EXTENDED_TEST_TIMEOUT,
    );

    it("should preserve golden state data after reset", async () => {
      // Right after a reset auth_db holds exactly the seeded personas
      const usernames = exec(
        `docker exec ${pgContainer} psql -U auth_user -d auth_db -t -A -c "SELECT username FROM users;"`,
      );
      expect(usernames.split("\n").sort()).toEqual(personas.map((p) => p.username).sort());

      const tables = exec(
        `docker exec ${pgContainer} psql -U auth_user -d auth_db -t -c "\\dt" | grep -E "(users|migrations)" | wc -l`,
      );
      expect(parseInt(tables)).toBe(2);
    });

    it(
      "should have fast restore times",
      async () => {
        // Do a restart and measure restore time from logs
        const restartedAt = new Date();
        exec("docker compose restart postgres");
        await waitForHealthy("postgres");

        const logs = logsSince("postgres", restartedAt);
        const restoreMatch = logs.match(/Database restore completed in (\d+\.\d{3}) seconds/);
        expect(restoreMatch).toBeTruthy();

        const restoreTime = parseFloat(restoreMatch?.[1] || "0");
        expect(restoreTime).toBeLessThanOrEqual(30);
      },
      EXTRA_EXTENDED_TEST_TIMEOUT,
    );

    it(
      "should keep the data after an unclean shutdown, and restore on the next clean restart",
      async () => {
        exec(`docker exec ${pgContainer} psql -U postgres -c "CREATE DATABASE test_db_crash;"`);
        const crashedAt = new Date();
        // An OOM kill looks the same to the next start; the restart policy ignores a manual kill
        exec("docker compose kill -s KILL postgres");
        exec("docker compose start postgres");
        await waitForHealthy("postgres");

        expect(logsSince("postgres", crashedAt)).toContain(
          "WARNING: PostgreSQL did not shut down cleanly (cluster state: in production).",
        );
        const kept = exec(
          `docker exec ${pgContainer} psql -U postgres -t -A -c "SELECT datname FROM pg_database WHERE datname='test_db_crash';"`,
        );
        expect(kept).toBe("test_db_crash");
        expect(exec(`docker exec ${pgContainer} cat /zoo-state/postgres`)).toContain(
          "kept=unclean shutdown (cluster state: in production)",
        );

        exec("docker compose restart postgres");
        await waitForHealthy("postgres");
        const restored = exec(
          `docker exec ${pgContainer} psql -U postgres -t -A -c "SELECT datname FROM pg_database WHERE datname='test_db_crash';"`,
        );
        expect(restored).toBe("");
        expect(exec(`docker exec ${pgContainer} cat /zoo-state/postgres`)).toMatch(/^kept=$/m);
      },
      EXTRA_EXTENDED_TEST_TIMEOUT,
    );

    it(
      "should reset Gitea's files with gitea_db or its golden files, and only then",
      async () => {
        for (const service of ["stalwart", "hydra", "auth-zoo"]) {
          await waitForHealthy(service, 120);
        }
        exec("docker compose --profile on-demand up -d gitea-zoo");
        await waitForHealthy("gitea-zoo", 180);
        const touchMarker = () => exec("docker compose exec -T gitea-zoo touch /data/test-marker");
        const hasMarker = () =>
          execMayFail("docker compose exec -T gitea-zoo test -f /data/test-marker").error ===
          undefined;
        const hasRepos = () =>
          exec("docker compose exec -T gitea-zoo ls /data/git/repositories/alice");

        // A restart of Gitea alone keeps its files, which still match the database
        touchMarker();
        exec("docker compose restart gitea-zoo");
        await waitForHealthy("gitea-zoo", 180);
        expect(hasMarker()).toBe(true);

        // As after a rebuild of the image with other golden files
        exec("docker compose exec -T gitea-zoo sh -c 'echo other > /data/.zoo-golden'");
        exec("docker compose restart gitea-zoo");
        await waitForHealthy("gitea-zoo", 180);
        expect(hasMarker()).toBe(false);
        expect(hasRepos()).toContain("hello-zoo.git");

        // A restore of postgres makes the running Gitea stop, and its restart restores /data.
        // Stalwart, which has no files, restarts too.
        touchMarker();
        const before = { gitea: startedAt("gitea-zoo"), stalwart: startedAt("stalwart") };
        exec("docker compose restart postgres");
        await waitForHealthy("postgres");
        await waitForRestart("gitea-zoo", before.gitea);
        await waitForRestart("stalwart", before.stalwart);
        await waitForHealthy("gitea-zoo", 180);
        await waitForHealthy("stalwart", 60);
        expect(hasMarker()).toBe(false);
        expect(hasRepos()).toContain("hello-zoo.git");
      },
      // Three Gitea starts and a postgres restore
      5 * EXTRA_EXTENDED_TEST_TIMEOUT,
    );
  });

  describe("MySQL", () => {
    it(
      "should restore from golden state on container creation",
      async () => {
        // Recreate container
        exec("docker compose rm -sfv mysql");
        exec("docker compose up -d mysql");

        // Check logs for restore message
        await waitForHealthy("mysql");
        const logs = exec("docker compose logs mysql --tail 50");
        expect(logs).toContain("Restoring MySQL database from golden state");
        expect(logs).toMatch(/Database restore completed in \d+\.\d{3} seconds/);
      },
      EXTRA_EXTENDED_TEST_TIMEOUT,
    ); // MySQL takes longer to start

    it(
      "should restore from golden state on container restart",
      async () => {
        // Create test data
        exec(`docker exec ${mysqlContainer} mysql -u root -e "CREATE DATABASE test_db_reset;"`);
        exec(
          `docker exec ${mysqlContainer} mysql -u vwa-classifieds_user -pvwa-classifieds_pw vwa-classifieds_db -e "CREATE TABLE test_table (id INT PRIMARY KEY);"`,
        );

        // Verify test data exists
        const databases = exec(
          `docker exec ${mysqlContainer} mysql -u root -e "SHOW DATABASES;" | grep test_db_reset`,
        );
        expect(databases).toContain("test_db_reset");

        // Restart container
        const restartedAt = new Date();
        exec("docker compose restart mysql");
        await waitForHealthy("mysql");

        // Check logs for restore message
        const logs = logsSince("mysql", restartedAt);
        expect(logs).toContain("Restoring MySQL database from golden state");
        expect(logs).toMatch(/Database restore completed in \d+\.\d{3} seconds/);

        // Verify test data is gone
        const dbResult = execMayFail(
          `docker exec ${mysqlContainer} mysql -u root -e "SHOW DATABASES;" | grep test_db_reset`,
        );
        expect(dbResult.error).toBeTruthy();
        expect(dbResult.output).toBeFalsy();

        // Verify test table is gone
        const tableResult = execMayFail(
          `docker exec ${mysqlContainer} mysql -u vwa-classifieds_user -pvwa-classifieds_pw vwa-classifieds_db -e "SELECT * FROM test_table;"`,
        );
        expect(tableResult.error).toContain("Table 'vwa-classifieds_db.test_table' doesn't exist");
      },
      EXTRA_EXTENDED_TEST_TIMEOUT,
    );

    it("should preserve golden state data after reset", async () => {
      // Check that original data exists - count lines excluding header and warning
      const tablesResult = exec(
        `docker exec ${mysqlContainer} mysql -u vwa-classifieds_user -pvwa-classifieds_pw vwa-classifieds_db -e "SHOW TABLES;" 2>&1`,
      );
      const tableLines = tablesResult
        .split("\n")
        .filter(
          (line) =>
            line.trim() &&
            !line.includes("Warning") &&
            !line.includes("Tables_in_vwa-classifieds_db"),
        );
      expect(tableLines.length).toBeGreaterThan(10); // Should have many tables

      const visits = exec(
        `docker exec ${mysqlContainer} mysql -u analytics_user -panalytics_pw analytics_db -N -e "SELECT count(*) FROM matomo_log_visit;" 2>/dev/null`,
      );
      expect(visits, "Matomo visits after a restore").toBe("0");

      // Check northwind database exists
      const northwind = exec(
        `docker exec ${mysqlContainer} mysql -u root -e "SHOW DATABASES;" | grep northwind`,
      );
      expect(northwind).toContain("northwind_db");
    });

    it(
      "should have reasonable restore times",
      async () => {
        // Do a restart and measure restore time from logs
        const restartedAt = new Date();
        exec("docker compose restart mysql");
        await waitForHealthy("mysql");

        const logs = logsSince("mysql", restartedAt);
        const restoreMatch = logs.match(/Database restore completed in (\d+\.\d{3}) seconds/);
        expect(restoreMatch).toBeTruthy();

        const restoreTime = parseFloat(restoreMatch?.[1] || "0");
        expect(restoreTime).toBeLessThanOrEqual(20); // MySQL has more data, allow more time
      },
      EXTENDED_TEST_TIMEOUT,
    );

    it(
      "should keep the data after an unclean shutdown, even one right after it kept the data",
      async () => {
        exec(`docker exec ${mysqlContainer} mysql -u root -e "CREATE DATABASE test_db_crash;"`);
        const crashedAt = new Date();
        exec("docker compose kill -s KILL mysql");
        exec("docker compose start mysql");
        await waitForHealthy("mysql", 60);

        expect(logsSince("mysql", crashedAt)).toContain(
          "WARNING: MySQL did not shut down cleanly (/var/lib/mysql/mysqld.pid was left behind).",
        );
        expect(
          exec(
            `docker exec ${mysqlContainer} mysql -u root -N -e "SHOW DATABASES LIKE 'test_db_crash';"`,
          ),
        ).toBe("test_db_crash");

        // Crash again as soon as the entrypoint keeps the data, before mysqld has written its
        // pid file (about a second later)
        const keeps = () =>
          exec(`docker logs ${mysqlContainer} 2>&1`).split("Keeping its data instead").length;
        exec(`docker kill -s KILL ${mysqlContainer}`);
        const before = keeps();
        exec(`docker start ${mysqlContainer}`);
        for (let i = 0; i < 200 && keeps() === before; i++) {
          await new Promise((resolve) => setTimeout(resolve, 50));
        }
        expect(keeps()).toBe(before + 1);
        exec(`docker kill -s KILL ${mysqlContainer}`);
        exec(`docker start ${mysqlContainer}`);
        await waitForHealthy("mysql", 60);
        expect(
          exec(
            `docker exec ${mysqlContainer} mysql -u root -N -e "SHOW DATABASES LIKE 'test_db_crash';"`,
          ),
        ).toBe("test_db_crash");

        exec("docker compose restart mysql");
        await waitForHealthy("mysql", 60);
        expect(
          exec(
            `docker exec ${mysqlContainer} mysql -u root -N -e "SHOW DATABASES LIKE 'test_db_crash';"`,
          ),
        ).toBe("");
      },
      3 * EXTRA_EXTENDED_TEST_TIMEOUT,
    );
  });

  describe("State in app containers", () => {
    it(
      "should start Microbin with no pastes",
      async () => {
        exec("docker compose --profile on-demand up -d --wait microbin");
        const pastes = async () => {
          const list = await fetchWithProxy("https://paste.zoo/list", {
            timeout: ON_DEMAND_FETCH_TIMEOUT,
          });
          expect(list.httpCode, list.error).toBe(200);
          return new Set(list.body.match(/\/upload\/[a-z-]+/g)).size;
        };
        const boundary = "zoo-database-reset";
        const fields = { expiration: "never", privacy: "public", content: "database-reset" };
        const upload = await fetchWithProxy("https://paste.zoo/upload", {
          method: "POST",
          headers: { "Content-Type": `multipart/form-data; boundary=${boundary}` },
          body: `${Object.entries(fields)
            .map(
              ([name, value]) =>
                `--${boundary}\r\nContent-Disposition: form-data; name="${name}"\r\n\r\n${value}\r\n`,
            )
            .join("")}--${boundary}--\r\n`,
          redirect: "manual",
          timeout: ON_DEMAND_FETCH_TIMEOUT,
        });
        expect(upload.httpCode, upload.error).toBe(302);
        expect(await pastes()).toBeGreaterThan(0);

        exec("docker compose restart microbin");
        await waitForHealthy("microbin", 60);
        expect(await pastes()).toBe(0);
      },
      EXTRA_EXTENDED_TEST_TIMEOUT,
    );

    it.skipIf(!isServiceAvailable("onestopshop"))(
      "should drop Onestopshop's Redis cache on every start and its sessions with a mysql restore",
      async () => {
        exec("docker compose --profile on-demand up -d --wait onestopshop");
        const shop = (command: string) => exec(`docker compose exec -T onestopshop ${command}`);
        const hasSession = () =>
          execMayFail("docker compose exec -T onestopshop test -f /var/lib/php/sessions/sess_zoo")
            .error === undefined;
        shop("redis-cli set zoo-database-reset cached");
        shop("redis-cli save");
        shop("touch /var/lib/php/sessions/sess_zoo");

        exec("docker compose restart onestopshop");
        await waitForHealthy("onestopshop", 180);
        expect(shop("redis-cli get zoo-database-reset")).toBe("");
        expect(hasSession()).toBe(true);

        const before = startedAt("onestopshop");
        exec("docker compose restart mysql");
        await waitForHealthy("mysql", 60);
        await waitForRestart("onestopshop", before);
        await waitForHealthy("onestopshop", 180);
        expect(hasSession()).toBe(false);
      },
      // Two Magento starts and a mysql restore
      6 * EXTRA_EXTENDED_TEST_TIMEOUT,
    );
  });

  // Clean up after tests
  afterAll(() => {
    console.log("Database golden state restoration tests completed");
  });
});
