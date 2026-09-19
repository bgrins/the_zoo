import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";

interface EnvResult {
  envPath: string;
  dnsIP: string;
  subnet: string;
  publicSubnet: string;
  caddyIP: string;
  proxyIP: string;
}

interface NetworkOptions {
  ipBase?: string; // Custom base IP (e.g., 172.30.100.1)
  port?: string; // The proxy port to use
  env?: Record<string, string>; // Extra variables to persist (from --set-env)
}

const ENV_LINE = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)$/;

/**
 * Format a value for a docker compose env file. Values with characters compose
 * would interpolate or strip ($, #, quotes, surrounding spaces) are quoted.
 */
function formatEnvValue(value: string): string {
  if (/^[\w.,:/@%+=?&*-]*$/.test(value)) {
    return value;
  }
  if (!value.includes("'")) {
    return `'${value}'`;
  }
  return `"${value.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\$/g, "$$$$")}"`;
}

function parseEnvValue(raw: string): string {
  const value = raw.trim();
  if (value.length >= 2 && value.startsWith("'") && value.endsWith("'")) {
    return value.slice(1, -1);
  }
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    return value
      .slice(1, -1)
      .replace(/\$\$/g, "$")
      .replace(/\\(["\\])/g, "$1");
  }
  return value.replace(/\s+#.*$/, "");
}

function parseEnvContent(content: string): Record<string, string> {
  const env: Record<string, string> = {};
  for (const line of content.split("\n")) {
    const match = line.match(ENV_LINE);
    if (match) {
      env[match[1]] = parseEnvValue(match[2]);
    }
  }
  return env;
}

/**
 * Set variables in env file content, replacing existing assignments in place
 * and appending new ones at the end.
 */
function applyEnvUpdates(content: string, updates: Record<string, string>): string {
  const remaining = new Map(Object.entries(updates));
  const lines = content.split("\n").map((line) => {
    const key = line.match(ENV_LINE)?.[1];
    if (key === undefined || !remaining.has(key)) {
      return line;
    }
    const value = remaining.get(key) ?? "";
    remaining.delete(key);
    return `${key}=${formatEnvValue(value)}`;
  });

  if (remaining.size > 0) {
    while (lines.length > 0 && lines[lines.length - 1] === "") {
      lines.pop();
    }
    lines.push("", "# Set with --set-env");
    for (const [key, value] of remaining) {
      lines.push(`${key}=${formatEnvValue(value)}`);
    }
    lines.push("");
  }
  return lines.join("\n");
}

/**
 * Read an instance env file. Returns null if it doesn't exist.
 */
export async function readEnvFile(envPath: string): Promise<Record<string, string> | null> {
  try {
    return parseEnvContent(await fs.readFile(envPath, "utf-8"));
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return null;
    }
    throw error;
  }
}

/**
 * Set variables in an existing env file and return its full contents.
 */
export async function updateEnvFile(
  envPath: string,
  updates: Record<string, string>,
): Promise<Record<string, string>> {
  const content = applyEnvUpdates(await fs.readFile(envPath, "utf-8"), updates);
  await fs.writeFile(envPath, content, "utf-8");
  return parseEnvContent(content);
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
  let publicSubnet: string;
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
    // Use next octet for public subnet (small /30 for just the proxy)
    const publicOctet = parseInt(octet2, 10) + 1;
    publicSubnet = `${octet1}.${publicOctet}.0.0/30`;

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
    // Use a different octet for public subnet to avoid overlap
    // Add 1 to secondOctet, wrapping if needed
    const publicOctet = secondOctet < 220 ? secondOctet + 1 : 21;
    publicSubnet = `172.${publicOctet}.0.0/30`;

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
# Public Subnet: ${publicSubnet}

# Network configuration
ZOO_SUBNET=${subnet}
ZOO_PUBLIC_SUBNET=${publicSubnet}
ZOO_DNS_IP=${dnsIP}
ZOO_CADDY_IP=${caddyIP}
ZOO_PROXY_IP=${proxyIP}
${options.port ? `ZOO_PROXY_PORT=${options.port}` : ""}

# Proxy authentication (optional, leave empty for no auth)
PROXY_USER=
PROXY_PASS=

# This file is used when restarting containers manually
# to ensure the same IP assignments are preserved
`;

  const envPath = path.join(versionPath, ".env");
  await fs.writeFile(envPath, applyEnvUpdates(envContent, options.env ?? {}), "utf-8");

  console.log(`Generated .env file with subnet: ${subnet}, public: ${publicSubnet}`);
  console.log(`DNS server will be at: ${dnsIP}`);
  console.log(`Caddy server will be at: ${caddyIP}`);
  console.log(`Proxy server will be at: ${proxyIP}`);

  return { envPath, dnsIP, subnet, publicSubnet, caddyIP, proxyIP };
}
