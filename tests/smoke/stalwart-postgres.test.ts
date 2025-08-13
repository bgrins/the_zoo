import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { getCachedContainerNames } from "../utils/test-cache";

const execAsync = promisify(exec);

describe("Stalwart PostgreSQL Storage", () => {
  let containers: Record<string, string> = {};

  beforeAll(async () => {
    containers = await getCachedContainerNames(["stalwart", "postgres"]);
  });

  test("Stalwart config should reference PostgreSQL storage", async () => {
    // Check the config file inside the container
    const { stdout: configContent } = await execAsync(
      `docker exec ${containers.stalwart} cat /opt/stalwart-mail/etc/config.toml | grep -A10 "\\[storage\\]"`,
    );

    expect(configContent).toContain('data = "postgresql"');
    expect(configContent).toContain('fts = "postgresql"');
    expect(configContent).toContain('blob = "postgresql"');
    expect(configContent).toContain('lookup = "postgresql"');
  });

  test("PostgreSQL should have Stalwart database", async () => {
    // Check that the Stalwart database exists in PostgreSQL
    const { stdout: dbList } = await execAsync(
      `docker exec ${containers.postgres} psql -U postgres -lqt | awk '{print $1}' | grep -E '^stalwart_db$'`,
    );

    expect(dbList.trim()).toBe("stalwart_db");
  });

  test("Stalwart API should show domains and users (stored in PostgreSQL)", async () => {
    // Make the API request from inside the container network
    const { stdout } = await execAsync(
      `docker exec ${containers.stalwart} curl -s -u "admin:zoo-mail-admin-pw" "http://localhost:8080/api/principal"`,
    );

    const data = JSON.parse(stdout);
    const items = data.data.items || [];

    // Check for domains
    const domains = items.filter((item: any) => item.type === "domain");
    const domainNames = domains.map((d: any) => d.name);
    expect(domainNames).toContain("zoo");
    expect(domainNames).toContain("status.zoo");
    expect(domainNames).toContain("snappymail.zoo");

    // Check for users
    const users = items.filter((item: any) => item.type === "individual");
    const userEmails = users.map((u: any) => u.name);
    expect(userEmails).toContain("user@zoo");
    expect(userEmails).toContain("admin@zoo");
    expect(userEmails).toContain("test@zoo");
  });

  test("Stalwart container should be stateless (recreatable)", async () => {
    // The data directory might exist due to the base image VOLUME directive,
    // but it should be empty or minimal since all data is in PostgreSQL
    const { stdout } = await execAsync(
      `docker exec ${containers.stalwart} du -sh /opt/stalwart-mail/data 2>/dev/null || echo "0K"`,
    );

    // Data directory should be very small (less than 1MB) since everything is in PostgreSQL
    const sizeMatch = stdout.match(/^(\d+(\.\d+)?)\s*([KMG])/);
    if (sizeMatch) {
      const size = parseFloat(sizeMatch[1]);
      const unit = sizeMatch[3];

      // Convert to KB for comparison
      let sizeInKB = size;
      if (unit === "M") sizeInKB = size * 1024;
      if (unit === "G") sizeInKB = size * 1024 * 1024;

      // Should be less than 1MB (1024 KB) - just minimal metadata
      expect(sizeInKB).toBeLessThan(1024);
    }
  });
});
