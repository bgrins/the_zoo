import { execFileSync } from "node:child_process";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { generateEnvFile, readEnvFile, updateEnvFile } from "../../cli/lib/utils/network-env";

const DEV_SUBNETS = ["172.20.0.0/16", "172.21.0.0/30", "172.22.0.0/16", "172.23.0.0/30"];

function secondOctet(cidr: string): number {
  return Number(cidr.split(".")[1]);
}

// A /16 in private 172.16.0.0/12, outside 172.16.0.0/16 (reserved for public /30s)
// and outside 172.20-172.23 (dev and fresh environments)
function isInstanceSubnet(cidr: string): boolean {
  const octet = secondOctet(cidr);
  return (
    /^172\.\d+\.0\.0\/16$/.test(cidr) && octet > 16 && octet <= 31 && (octet < 20 || octet > 23)
  );
}

function isPublicSubnet(cidr: string): boolean {
  const match = cidr.match(/^172\.16\.(\d+)\.(\d+)\/30$/);
  return match !== null && Number(match[2]) % 4 === 0;
}

describe("Network Environment Configuration", () => {
  const testDir = path.join(os.tmpdir(), `thezoo-network-test-${Date.now()}`);

  beforeAll(async () => {
    await fs.mkdir(testDir, { recursive: true });
  });

  beforeEach(() => {
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  afterAll(async () => {
    await fs.rm(testDir, { recursive: true, force: true });
  });

  it("should generate .env file with network configuration", async () => {
    const result = await generateEnvFile(testDir, "test-project-123", { usedSubnets: [] });

    const env = await readEnvFile(result.envPath);
    expect(result.envPath).toBe(path.join(testDir, ".env"));
    expect(env).toMatchObject({
      ZOO_SUBNET: result.subnet,
      ZOO_PUBLIC_SUBNET: result.publicSubnet,
      ZOO_DNS_IP: result.dnsIP,
      ZOO_CADDY_IP: result.caddyIP,
      ZOO_PROXY_IP: result.proxyIP,
      PROXY_USER: "",
      PROXY_PASS: "",
    });
  });

  it("should generate consistent configuration for same project name", async () => {
    const result1 = await generateEnvFile(testDir, "test-consistency", { usedSubnets: [] });
    const result2 = await generateEnvFile(testDir, "test-consistency", { usedSubnets: [] });

    expect(result2).toEqual(result1);
  });

  it("should keep instance subnets private and away from the dev and fresh environments", async () => {
    const names = Array.from({ length: 200 }, (_, i) => `thezoo-cli-instance-${i}-v0-9-0`);

    for (const name of names) {
      const result = await generateEnvFile(testDir, name, { usedSubnets: [] });

      expect(isInstanceSubnet(result.subnet), result.subnet).toBe(true);
      expect([20, 21, 22, 23]).not.toContain(secondOctet(result.subnet));
      expect(isPublicSubnet(result.publicSubnet), result.publicSubnet).toBe(true);
      expect(result.dnsIP).toMatch(/^172\.\d+\.(24\d|25[0-5])\.2$/);
      expect(result.caddyIP).toBe(result.dnsIP.replace(/\.2$/, ".3"));
      expect(result.proxyIP).toBe(result.dnsIP.replace(/\.2$/, ".4"));
      expect(result.dnsIP.startsWith(`172.${secondOctet(result.subnet)}.`)).toBe(true);
    }
  });

  it("should not overlap the dev environment for the default instance", async () => {
    // md5 of this name starts with 0x00, which used to map to 172.21.0.0/16
    const result = await generateEnvFile(testDir, "thezoo-cli-instance-default-v0-9-0", {
      usedSubnets: DEV_SUBNETS,
    });

    expect(isInstanceSubnet(result.subnet)).toBe(true);
    expect(isPublicSubnet(result.publicSubnet)).toBe(true);
  });

  it("should skip subnets used by existing Docker networks", async () => {
    const first = await generateEnvFile(testDir, "project-alpha", { usedSubnets: [] });
    const second = await generateEnvFile(testDir, "project-alpha", {
      usedSubnets: [first.subnet, first.publicSubnet],
    });

    expect(second.subnet).not.toBe(first.subnet);
    expect(second.publicSubnet).not.toBe(first.publicSubnet);
    expect(isInstanceSubnet(second.subnet)).toBe(true);
    expect(isPublicSubnet(second.publicSubnet)).toBe(true);
  });

  it("should skip subnets that partially overlap existing networks", async () => {
    const first = await generateEnvFile(testDir, "project-beta", { usedSubnets: [] });
    const octet = secondOctet(first.subnet);
    const second = await generateEnvFile(testDir, "project-beta", {
      usedSubnets: [`172.${octet}.128.0/20`],
    });

    expect(second.subnet).not.toBe(first.subnet);
  });

  it("should fail clearly when every candidate subnet is taken", async () => {
    await expect(
      generateEnvFile(testDir, "project-full", { usedSubnets: ["172.16.0.0/12"] }),
    ).rejects.toThrow("No free 172.x.0.0/16 subnet");
  });

  it("should accept custom base IP option", async () => {
    const result = await generateEnvFile(testDir, "test-custom-ip", {
      ipBase: "10.50.100.10",
      usedSubnets: [],
    });

    expect(result.subnet).toBe("10.50.0.0/16");
    expect(isPublicSubnet(result.publicSubnet)).toBe(true);
    expect(result.dnsIP).toBe("10.50.100.11");
    expect(result.caddyIP).toBe("10.50.100.12");
    expect(result.proxyIP).toBe("10.50.100.13");
  });

  it("should reject a base IP whose subnet overlaps an existing network", async () => {
    await expect(
      generateEnvFile(testDir, "test-custom-overlap", {
        ipBase: "172.20.100.1",
        usedSubnets: DEV_SUBNETS,
      }),
    ).rejects.toThrow("Subnet 172.20.0.0/16 (from --ip-base) overlaps an existing Docker network");
  });

  it("should throw error for invalid IP format", async () => {
    await expect(
      generateEnvFile(testDir, "test-invalid", { ipBase: "not-an-ip", usedSubnets: [] }),
    ).rejects.toThrow("Invalid IP format");
  });

  it("should throw error for base IP too high", async () => {
    await expect(
      generateEnvFile(testDir, "test-invalid", { ipBase: "172.30.100.253", usedSubnets: [] }),
    ).rejects.toThrow("Base IP too high");
  });

  it("should allow base IP up to .252", async () => {
    const result = await generateEnvFile(testDir, "test-high-base", {
      ipBase: "172.30.100.252",
      usedSubnets: [],
    });

    expect(result.dnsIP).toBe("172.30.100.253");
    expect(result.caddyIP).toBe("172.30.100.254");
    expect(result.proxyIP).toBe("172.30.100.255");
  });
});

describe("Instance env file values", () => {
  let dir: string;

  beforeAll(async () => {
    dir = await fs.mkdtemp(path.join(os.tmpdir(), "thezoo-env-values-"));
  });

  beforeEach(() => {
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  afterAll(async () => {
    await fs.rm(dir, { recursive: true, force: true });
  });

  const values = {
    PLAIN: "postgresql://user:pass@host:5432/db?option=value",
    DOLLARS: "pa$$ w#rd",
    QUOTES: `it's "quoted" $HOME`,
    EMPTY: "",
  };

  it("should round-trip values through readEnvFile and updateEnvFile", async () => {
    const { envPath } = await generateEnvFile(dir, "test-values", {
      usedSubnets: [],
      env: values,
    });

    expect(await readEnvFile(envPath)).toMatchObject(values);

    const updated = await updateEnvFile(envPath, { DOLLARS: "changed", NEW_VAR: "1" });
    expect(updated).toMatchObject({ ...values, DOLLARS: "changed", NEW_VAR: "1" });
    const content = await fs.readFile(envPath, "utf-8");
    expect(content.match(/^DOLLARS=/gm)).toHaveLength(1);
  });

  it("should write values docker compose reads back unchanged", async () => {
    const { envPath } = await generateEnvFile(dir, "test-compose", {
      usedSubnets: [],
      env: values,
    });
    const composePath = path.join(dir, "compose.yaml");
    const environment = Object.keys(values)
      .map((key) => `      ${key}: \${${key}}`)
      .join("\n");
    await fs.writeFile(
      composePath,
      `services:\n  app:\n    image: busybox\n    environment:\n${environment}\n`,
    );

    const config = JSON.parse(
      execFileSync(
        "docker",
        [
          "compose",
          "-f",
          composePath,
          "--env-file",
          envPath,
          "-p",
          "thezoo-env-test",
          "config",
          "--format",
          "json",
        ],
        { encoding: "utf-8", stdio: ["ignore", "pipe", "pipe"] },
      ),
    );

    // compose escapes literal $ as $$ in its rendered config
    const rendered = Object.fromEntries(
      Object.entries(config.services.app.environment as Record<string, string>).map(
        ([key, value]) => [key, value.replace(/\$\$/g, "$")],
      ),
    );
    expect(rendered).toEqual(values);
  });
});
