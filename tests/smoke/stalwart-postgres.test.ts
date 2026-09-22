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
    expect(domainNames.sort()).toEqual(["snappymail.zoo", "zoo"]);

    // Check for users
    const users = items.filter((item: any) => item.type === "individual");
    const userEmails = users.map((u: any) => u.name);
    expect(userEmails).toContain("user@zoo");
    expect(userEmails).toContain("admin@zoo");
    expect(userEmails).toContain("test@zoo");
  });

  test("Stalwart container should be stateless (recreatable)", async () => {
    // /opt/stalwart-mail is the image's VOLUME; with all storage in PostgreSQL it should
    // hold nothing but the config directory.
    const { stdout: entries } = await execAsync(
      `docker exec ${containers.stalwart} ls -A /opt/stalwart-mail`,
    );
    expect(entries.trim().split("\n")).toEqual(["etc"]);

    const { stdout: size } = await execAsync(
      `docker exec ${containers.stalwart} du -sk /opt/stalwart-mail`,
    );
    expect(Number.parseInt(size, 10)).toBeLessThan(1024);
  });
});
