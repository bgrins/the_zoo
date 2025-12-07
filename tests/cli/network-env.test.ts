import { describe, it, beforeAll, afterAll, expect } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import { generateEnvFile } from "../../cli/lib/utils/network-env";

describe("Network Environment Configuration", () => {
  const testDir = path.join(os.tmpdir(), `thezoo-network-test-${Date.now()}`);

  beforeAll(async () => {
    // Create test directory
    await fs.mkdir(testDir, { recursive: true });
  });

  afterAll(async () => {
    // Clean up test directory
    await fs.rm(testDir, { recursive: true, force: true });
  });

  it("should generate .env file with network configuration", async () => {
    const projectName = "test-project-123";

    const result = await generateEnvFile(testDir, projectName);

    expect(result.envPath).toBeTruthy();
    expect(result.envPath).toContain(testDir);
    expect(result.dnsIP).toBeTruthy();
    expect(result.subnet).toBeTruthy();
    expect(result.publicSubnet).toBeTruthy();
    expect(result.caddyIP).toBeTruthy();
    expect(result.proxyIP).toBeTruthy();

    // Check that .env file was created
    const envContent = await fs.readFile(result.envPath, "utf-8");
    expect(envContent).toContain("ZOO_SUBNET=");
    expect(envContent).toContain("ZOO_PUBLIC_SUBNET=");
    expect(envContent).toContain("ZOO_DNS_IP=");
    expect(envContent).toContain("ZOO_CADDY_IP=");
    expect(envContent).toContain("ZOO_PROXY_IP=");

    // Check that proxy auth variables are included (empty by default)
    expect(envContent).toContain("PROXY_USER=");
    expect(envContent).toContain("PROXY_PASS=");
  });

  it("should generate unique subnets for different projects", async () => {
    const project1 = "project-alpha";
    const project2 = "project-beta-different";

    const result1 = await generateEnvFile(testDir, project1);
    const result2 = await generateEnvFile(testDir, project2);

    expect(result1.subnet).not.toBe(result2.subnet);
    expect(result1.publicSubnet).not.toBe(result2.publicSubnet);
    expect(result1.dnsIP).not.toBe(result2.dnsIP);
  });

  it("should use high third octet range (240-255) to avoid conflicts", async () => {
    const projectName = "test-high-range";
    const result = await generateEnvFile(testDir, projectName);

    // Validate IPs use high third octet range (240-255)
    expect(result.dnsIP).toMatch(/^172\.\d+\.(2[4-5]\d|25[0-5])\.2$/);
    expect(result.caddyIP).toMatch(/^172\.\d+\.(2[4-5]\d|25[0-5])\.3$/);
    expect(result.proxyIP).toMatch(/^172\.\d+\.(2[4-5]\d|25[0-5])\.4$/);

    // Extract and verify third octet is in range 240-255
    const thirdOctet = parseInt(result.dnsIP.split(".")[2], 10);
    expect(thirdOctet).toBeGreaterThanOrEqual(240);
    expect(thirdOctet).toBeLessThanOrEqual(255);
  });

  it("should generate valid IP addresses and subnet", async () => {
    const projectName = "test-ips";
    const result = await generateEnvFile(testDir, projectName);

    // Validate IP format
    const ipRegex = /^172\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;
    expect(result.dnsIP).toMatch(ipRegex);
    expect(result.caddyIP).toMatch(ipRegex);
    expect(result.proxyIP).toMatch(ipRegex);

    // Validate subnet format
    const subnetRegex = /^172\.\d{1,3}\.0\.0\/16$/;
    expect(result.subnet).toMatch(subnetRegex);

    // Validate public subnet format (small /30 subnet)
    const publicSubnetRegex = /^172\.\d{1,3}\.0\.0\/30$/;
    expect(result.publicSubnet).toMatch(publicSubnetRegex);
  });

  it("should generate consistent configuration for same project name", async () => {
    const projectName = "test-consistency";

    const result1 = await generateEnvFile(testDir, projectName);
    const result2 = await generateEnvFile(testDir, projectName);

    expect(result1.subnet).toBe(result2.subnet);
    expect(result1.publicSubnet).toBe(result2.publicSubnet);
    expect(result1.dnsIP).toBe(result2.dnsIP);
    expect(result1.caddyIP).toBe(result2.caddyIP);
    expect(result1.proxyIP).toBe(result2.proxyIP);
  });

  it("should generate subnets in valid range (21-220)", async () => {
    const testNames = ["test1", "test2", "test3", "long-project-name", "short"];

    for (const name of testNames) {
      const result = await generateEnvFile(testDir, name);
      const subnetMatch = result.subnet.match(/172\.(\d+)\.0\.0\/16/);
      expect(subnetMatch).toBeTruthy();

      if (subnetMatch) {
        const octet = parseInt(subnetMatch[1], 10);
        expect(octet).toBeGreaterThanOrEqual(21);
        expect(octet).toBeLessThanOrEqual(220);
      }
    }
  });

  it("should generate non-overlapping public subnet", async () => {
    const testNames = ["test1", "test2", "test3", "long-project-name", "short"];

    for (const name of testNames) {
      const result = await generateEnvFile(testDir, name);

      // Extract second octet from both subnets
      const subnetMatch = result.subnet.match(/172\.(\d+)\.0\.0\/16/);
      const publicSubnetMatch = result.publicSubnet.match(/172\.(\d+)\.0\.0\/30/);

      expect(subnetMatch).toBeTruthy();
      expect(publicSubnetMatch).toBeTruthy();

      if (subnetMatch && publicSubnetMatch) {
        const subnetOctet = parseInt(subnetMatch[1], 10);
        const publicOctet = parseInt(publicSubnetMatch[1], 10);

        // Public subnet must use a different second octet to avoid overlap
        expect(publicOctet).not.toBe(subnetOctet);
      }
    }
  });

  it("should accept custom base IP option", async () => {
    const projectName = "test-custom-ip";
    const result = await generateEnvFile(testDir, projectName, {
      ipBase: "10.50.100.10",
    });

    expect(result.subnet).toBe("10.50.0.0/16");
    expect(result.publicSubnet).toBe("10.51.0.0/30");
    expect(result.dnsIP).toBe("10.50.100.11");
    expect(result.caddyIP).toBe("10.50.100.12");
    expect(result.proxyIP).toBe("10.50.100.13");
  });

  it("should derive subnet from base IP", async () => {
    const projectName = "test-subnet-derivation";
    const result = await generateEnvFile(testDir, projectName, {
      ipBase: "192.168.50.100",
    });

    expect(result.subnet).toBe("192.168.0.0/16");
    expect(result.publicSubnet).toBe("192.169.0.0/30");
    expect(result.dnsIP).toBe("192.168.50.101");
    expect(result.caddyIP).toBe("192.168.50.102");
    expect(result.proxyIP).toBe("192.168.50.103");
  });

  it("should throw error for invalid IP format", async () => {
    await expect(
      generateEnvFile(testDir, "test-invalid", {
        ipBase: "not-an-ip",
      }),
    ).rejects.toThrow("Invalid IP format");
  });

  it("should throw error for base IP too high", async () => {
    await expect(
      generateEnvFile(testDir, "test-invalid", {
        ipBase: "172.20.100.253",
      }),
    ).rejects.toThrow("Base IP too high");
  });

  it("should allow base IP up to .252", async () => {
    const projectName = "test-high-base";
    const result = await generateEnvFile(testDir, projectName, {
      ipBase: "172.20.100.252",
    });

    expect(result.dnsIP).toBe("172.20.100.253");
    expect(result.caddyIP).toBe("172.20.100.254");
    expect(result.proxyIP).toBe("172.20.100.255");
  });
});
