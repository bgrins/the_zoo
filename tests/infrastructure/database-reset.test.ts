import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { execSync } from "node:child_process";
import { getCachedContainerName } from "../utils/test-cache";
import { EXTENDED_TEST_TIMEOUT, EXTRA_EXTENDED_TEST_TIMEOUT } from "../constants";

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

// Helper to wait for container to be healthy
async function waitForHealthy(service: string, maxAttempts = 30): Promise<void> {
  for (let i = 0; i < maxAttempts; i++) {
    try {
      const result = execMayFail(`docker compose ps ${service} --format "{{.Health}}"`);
      if (result.output?.includes("healthy")) {
        return;
      }
    } catch {
      // Container might not exist yet
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  throw new Error(`${service} did not become healthy within ${maxAttempts} seconds`);
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

describe.skipIf(!shouldRun)("Database Golden State Restoration", () => {
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
        exec("docker compose down postgres");
        exec("docker compose up -d postgres");

        // Check logs for restore message
        await waitForHealthy("postgres");
        const logs = exec("docker compose logs postgres --tail 50");
        expect(logs).toContain("Restoring PostgreSQL database from golden state");
        expect(logs).toMatch(/Database restore completed in \d+ seconds/);
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
        exec("docker compose restart postgres");
        await waitForHealthy("postgres");

        // Check logs for restore message
        const logs = exec("docker compose logs postgres --tail 30");
        expect(logs).toContain("Restoring PostgreSQL database from golden state");
        expect(logs).toMatch(/Database restore completed in \d+ seconds/);

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
      // Check that original data exists
      const userCount = exec(
        `docker exec ${pgContainer} psql -U auth_user -d auth_db -t -c "SELECT COUNT(*) FROM users;"`,
      );
      expect(parseInt(userCount)).toBe(13);

      const tables = exec(
        `docker exec ${pgContainer} psql -U auth_user -d auth_db -t -c "\\dt" | grep -E "(users|migrations)" | wc -l`,
      );
      expect(parseInt(tables)).toBe(2);
    });

    it("should have fast restore times", async () => {
      // Do a restart and measure restore time from logs
      exec("docker compose restart postgres");
      await waitForHealthy("postgres");

      const logs = exec("docker compose logs postgres --tail 30");
      const restoreMatch = logs.match(/Database restore completed in (\d+) seconds/);
      expect(restoreMatch).toBeTruthy();

      const restoreTime = parseInt(restoreMatch?.[1] || "0");
      expect(restoreTime).toBeLessThanOrEqual(10); // Should be much faster, but allow some margin
    });
  });

  describe("MySQL", () => {
    it(
      "should restore from golden state on container creation",
      async () => {
        // Recreate container
        exec("docker compose down mysql");
        exec("docker compose up -d mysql");

        // Check logs for restore message
        await waitForHealthy("mysql");
        const logs = exec("docker compose logs mysql --tail 50");
        expect(logs).toContain("Restoring MySQL database from golden state");
        expect(logs).toMatch(/Database restore completed in \d+ seconds/);
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
        exec("docker compose restart mysql");
        await waitForHealthy("mysql");

        // Check logs for restore message
        const logs = exec("docker compose logs mysql --tail 30");
        expect(logs).toContain("Restoring MySQL database from golden state");
        expect(logs).toMatch(/Database restore completed in \d+ seconds/);

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
        exec("docker compose restart mysql");
        await waitForHealthy("mysql");

        const logs = exec("docker compose logs mysql --tail 30");
        const restoreMatch = logs.match(/Database restore completed in (\d+) seconds/);
        expect(restoreMatch).toBeTruthy();

        const restoreTime = parseInt(restoreMatch?.[1] || "0");
        expect(restoreTime).toBeLessThanOrEqual(20); // MySQL has more data, allow more time
      },
      EXTENDED_TEST_TIMEOUT,
    );
  });

  // Clean up after tests
  afterAll(() => {
    console.log("Database golden state restoration tests completed");
  });
});
