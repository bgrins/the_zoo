import { execFileSync } from "node:child_process";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  allocateNetwork,
  applyEnvUpdates,
  findSubnetConflicts,
  parseEnvContent,
  readEnvFile,
  renderEnvFile,
} from "../../cli/lib/utils/network-env";

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
  it("should render an env file with the network configuration", async () => {
    const { content, network } = await renderEnvFile("test-project-123", {
      port: "3128",
      usedSubnets: [],
    });

    expect(parseEnvContent(content)).toEqual({
      ZOO_SUBNET: network.subnet,
      ZOO_PUBLIC_SUBNET: network.publicSubnet,
      ZOO_DNS_IP: network.dnsIP,
      ZOO_CADDY_IP: network.caddyIP,
      ZOO_PROXY_IP: network.proxyIP,
      ZOO_PROXY_PORT: "3128",
      PROXY_USER: "",
      PROXY_PASS: "",
    });
  });

  it("should record --ip-base in the env file", async () => {
    const { content } = await renderEnvFile("test-ip-base", {
      ipBase: "172.30.100.1",
      usedSubnets: [],
    });

    expect(parseEnvContent(content).ZOO_IP_BASE).toBe("172.30.100.1");
  });

  it("should generate consistent configuration for same project name", async () => {
    const result1 = await allocateNetwork("test-consistency", { usedSubnets: [] });
    const result2 = await allocateNetwork("test-consistency", { usedSubnets: [] });

    expect(result2).toEqual(result1);
  });

  it("should keep instance subnets private and away from the dev and fresh environments", async () => {
    const names = Array.from({ length: 200 }, (_, i) => `thezoo-cli-instance-${i}-v0-9-0`);

    for (const name of names) {
      const result = await allocateNetwork(name, { usedSubnets: [] });

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
    const result = await allocateNetwork("thezoo-cli-instance-default-v0-9-0", {
      usedSubnets: DEV_SUBNETS,
    });

    expect(isInstanceSubnet(result.subnet)).toBe(true);
    expect(isPublicSubnet(result.publicSubnet)).toBe(true);
  });

  it("should skip subnets used by existing Docker networks", async () => {
    const first = await allocateNetwork("project-alpha", { usedSubnets: [] });
    const second = await allocateNetwork("project-alpha", {
      usedSubnets: [first.subnet, first.publicSubnet],
    });

    expect(second.subnet).not.toBe(first.subnet);
    expect(second.publicSubnet).not.toBe(first.publicSubnet);
    expect(isInstanceSubnet(second.subnet)).toBe(true);
    expect(isPublicSubnet(second.publicSubnet)).toBe(true);
  });

  it("should skip subnets that partially overlap existing networks", async () => {
    const first = await allocateNetwork("project-beta", { usedSubnets: [] });
    const octet = secondOctet(first.subnet);
    const second = await allocateNetwork("project-beta", {
      usedSubnets: [`172.${octet}.128.0/20`],
    });

    expect(second.subnet).not.toBe(first.subnet);
  });

  it("should fail clearly when every candidate subnet is taken", async () => {
    await expect(
      allocateNetwork("project-full", { usedSubnets: ["172.16.0.0/12"] }),
    ).rejects.toThrow("No free 172.x.0.0/16 subnet");
  });

  it("should find saved subnets that overlap existing networks", () => {
    const env = { ZOO_SUBNET: "172.27.0.0/16", ZOO_PUBLIC_SUBNET: "172.16.4.0/30" };

    expect(findSubnetConflicts(env, [])).toEqual([]);
    expect(findSubnetConflicts(env, ["172.26.0.0/16", "172.16.8.0/30"])).toEqual([]);
    expect(findSubnetConflicts(env, ["172.27.240.0/20"])).toEqual(["172.27.0.0/16"]);
    expect(findSubnetConflicts(env, ["172.16.0.0/16"])).toEqual(["172.16.4.0/30"]);
  });

  it("should accept custom base IP option", async () => {
    const result = await allocateNetwork("test-custom-ip", {
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
      allocateNetwork("test-custom-overlap", {
        ipBase: "172.20.100.1",
        usedSubnets: DEV_SUBNETS,
      }),
    ).rejects.toThrow("Subnet 172.20.0.0/16 (from --ip-base) overlaps an existing Docker network");
  });

  it("should throw error for invalid IP format", async () => {
    await expect(
      allocateNetwork("test-invalid", { ipBase: "not-an-ip", usedSubnets: [] }),
    ).rejects.toThrow("Invalid IP format");
  });

  it("should throw error for base IP too high", async () => {
    await expect(
      allocateNetwork("test-invalid", { ipBase: "172.30.100.253", usedSubnets: [] }),
    ).rejects.toThrow("Base IP too high");
  });

  it("should allow base IP up to .252", async () => {
    const result = await allocateNetwork("test-high-base", {
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

  afterAll(async () => {
    await fs.rm(dir, { recursive: true, force: true });
  });

  const values = {
    PLAIN: "postgresql://user:pass@host:5432/db?option=value",
    DOLLARS: "pa$$ w#rd",
    QUOTES: `it's "quoted" $HOME`,
    BACKSLASHES: "C:\\dir\\",
    BACKSLASH_QUOTE: "a\\'b\\\"c",
    EMPTY: "",
  };

  async function writeEnvFile(name: string): Promise<string> {
    const { content } = await renderEnvFile(name, { usedSubnets: [], env: values });
    const envPath = path.join(dir, `${name}.env`);
    await fs.writeFile(envPath, content);
    return envPath;
  }

  it("should round-trip values through the env file and updates", async () => {
    const envPath = await writeEnvFile("test-values");

    expect(await readEnvFile(envPath)).toMatchObject(values);

    const content = applyEnvUpdates(await fs.readFile(envPath, "utf-8"), {
      DOLLARS: "changed",
      NEW_VAR: "1",
    });
    expect(parseEnvContent(content)).toMatchObject({ ...values, DOLLARS: "changed", NEW_VAR: "1" });
    expect(content.match(/^DOLLARS=/gm)).toHaveLength(1);
  });

  it("should write values docker compose reads back unchanged", async () => {
    const envPath = await writeEnvFile("test-compose");
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
