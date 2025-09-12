import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";

interface EnvResult {
  envPath: string;
  dnsIP: string;
  subnet: string;
  caddyIP: string;
  proxyIP: string;
}

interface NetworkOptions {
  ipBase?: string; // Custom base IP (e.g., 172.30.100.1)
  proxyPort?: string; // The proxy port to use
}

/**
 * Generate a .env file with high-range IP assignments within a random subnet
 * This replaces the docker-compose.override.yml approach
 */
export async function generateEnvFile(
  versionPath: string,
  projectName: string,
  options: NetworkOptions = {},
): Promise<EnvResult> {
  let subnet: string;
  let dnsIP: string;
  let caddyIP: string;
  let proxyIP: string;

  if (options.ipBase) {
    // Parse base IP
    const ipMatch = options.ipBase.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
    if (!ipMatch) {
      throw new Error(`Invalid IP format: ${options.ipBase}. Expected format: x.x.x.x`);
    }

    const [, octet1, octet2, octet3, octet4] = ipMatch;
    const lastOctet = parseInt(octet4, 10);

    // Validate that we have room for at least 3 consecutive IPs
    if (lastOctet > 252) {
      throw new Error(
        `Base IP too high: ${options.ipBase}. Need room for at least 3 IPs (base + 1, 2, 3)`,
      );
    }

    // Derive subnet from the base IP (assuming /16)
    subnet = `${octet1}.${octet2}.0.0/16`;

    // Assign consecutive IPs starting from base + 1
    dnsIP = `${octet1}.${octet2}.${octet3}.${lastOctet + 1}`;
    caddyIP = `${octet1}.${octet2}.${octet3}.${lastOctet + 2}`;
    proxyIP = `${octet1}.${octet2}.${octet3}.${lastOctet + 3}`;
  } else {
    // Generate a random subnet within the 172.16.0.0/12 range
    // Using range 172.21.0.0/16 to 172.220.0.0/16 for compatibility
    const hash = crypto.createHash("md5").update(projectName).digest();
    const secondOctet = 21 + (hash[0] % 200); // Range: 21-220
    subnet = `172.${secondOctet}.0.0/16`;

    // Use high third octet range (240-255) with randomization to avoid conflicts
    const thirdOctet = 240 + (hash[1] % 16);

    dnsIP = `172.${secondOctet}.${thirdOctet}.2`;
    caddyIP = `172.${secondOctet}.${thirdOctet}.3`;
    proxyIP = `172.${secondOctet}.${thirdOctet}.4`;
  }

  // Create .env file content
  const envContent = `# Auto-generated environment file for Zoo instance
# Project: ${projectName}
# Subnet: ${subnet}

# Network configuration
ZOO_SUBNET=${subnet}
ZOO_DNS_IP=${dnsIP}
ZOO_CADDY_IP=${caddyIP}
ZOO_PROXY_IP=${proxyIP}
${options.proxyPort ? `ZOO_PROXY_PORT=${options.proxyPort}` : ""}

# This file is used when restarting containers manually
# to ensure the same IP assignments are preserved
`;

  const envPath = path.join(versionPath, ".env");
  await fs.writeFile(envPath, envContent, "utf-8");

  console.log(`Generated .env file with subnet: ${subnet}`);
  console.log(`DNS server will be at: ${dnsIP}`);
  console.log(`Caddy server will be at: ${caddyIP}`);
  console.log(`Proxy server will be at: ${proxyIP}`);

  return { envPath, dnsIP, subnet, caddyIP, proxyIP };
}
