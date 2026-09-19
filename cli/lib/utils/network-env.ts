import crypto from "node:crypto";
import fs from "node:fs/promises";
import { execCommand } from "./docker";

export interface NetworkConfig {
  subnet: string;
  publicSubnet: string;
  dnsIP: string;
  caddyIP: string;
  proxyIP: string;
}

interface NetworkOptions {
  ipBase?: string; // Custom base IP (e.g., 172.30.100.1)
  usedSubnets?: string[]; // Subnets to avoid; defaults to those of existing Docker networks
}

interface EnvFileOptions extends NetworkOptions {
  port?: string; // The proxy port to use
  env?: Record<string, string>; // Extra variables to persist (from --set-env)
}

// Instance subnets are /16s inside the private 172.16.0.0/12 block. 172.20-172.23
// belong to the dev and fresh environments, and 172.16.0.0/16 (outside Docker's
// default address pools) is reserved for the instances' /30 public subnets.
const INSTANCE_SECOND_OCTETS = [17, 18, 19, 24, 25, 26, 27, 28, 29, 30, 31];
const PUBLIC_BLOCK_START = 172 * 2 ** 24 + 16 * 2 ** 16;
const PUBLIC_BLOCK_SLOTS = 2 ** 16 / 4;

interface IPv4Range {
  start: number;
  end: number;
}

function parseCidr(cidr: string): IPv4Range | null {
  const match = cidr.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)\/(\d+)$/);
  if (!match) {
    return null;
  }
  const [a, b, c, d, bits] = match.slice(1).map(Number);
  if ([a, b, c, d].some((octet) => octet > 255) || bits > 32) {
    return null;
  }
  const address = a * 2 ** 24 + b * 2 ** 16 + c * 2 ** 8 + d;
  const size = 2 ** (32 - bits);
  const start = address - (address % size);
  return { start, end: start + size - 1 };
}

function formatIPv4(address: number): string {
  return [24, 16, 8, 0].map((shift) => Math.floor(address / 2 ** shift) % 256).join(".");
}

function overlaps(cidr: string, used: IPv4Range[]): boolean {
  const range = parseCidr(cidr);
  return range !== null && used.some((u) => range.start <= u.end && u.start <= range.end);
}

function toRanges(subnets: string[]): IPv4Range[] {
  return subnets.map(parseCidr).filter((range): range is IPv4Range => range !== null);
}

/**
 * Pick a free /30 for the instance's public (proxy) network from the reserved block
 */
function allocatePublicSubnet(seed: number, used: IPv4Range[]): string {
  for (let i = 0; i < PUBLIC_BLOCK_SLOTS; i++) {
    const start = PUBLIC_BLOCK_START + ((seed + i) % PUBLIC_BLOCK_SLOTS) * 4;
    const cidr = `${formatIPv4(start)}/30`;
    if (!overlaps(cidr, used)) {
      return cidr;
    }
  }
  throw new Error("No free /30 public subnet left in 172.16.0.0/16");
}

/**
 * Subnets of existing Docker networks, other than the project's own
 */
export async function getDockerSubnets(projectName: string): Promise<string[]> {
  try {
    const { stdout: ids } = await execCommand("docker", ["network", "ls", "-q"]);
    const networkIds = ids.split("\n").filter(Boolean);
    if (networkIds.length === 0) {
      return [];
    }
    const { stdout } = await execCommand("docker", ["network", "inspect", ...networkIds]);
    const networks: Array<{
      Labels?: Record<string, string> | null;
      IPAM?: { Config?: Array<{ Subnet?: string }> | null };
    }> = JSON.parse(stdout);
    return networks
      .filter((network) => network.Labels?.["com.docker.compose.project"] !== projectName)
      .flatMap((network) => network.IPAM?.Config ?? [])
      .map((config) => config.Subnet)
      .filter((subnet): subnet is string => Boolean(subnet));
  } catch {
    // Docker unavailable: fall back to the deterministic choice
    return [];
  }
}

const ENV_LINE = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)$/;

/**
 * Format a value for a docker compose env file. Values with characters compose
 * would interpolate or strip ($, #, quotes, surrounding spaces) are quoted.
 * Compose treats a backslash before the closing single quote as an escape, so
 * values with backslashes are double-quoted with escapes.
 */
function formatEnvValue(value: string): string {
  if (/^[\w.,:/@%+=?&*-]*$/.test(value)) {
    return value;
  }
  if (!value.includes("'") && !value.includes("\\")) {
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

export function parseEnvContent(content: string): Record<string, string> {
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
export function applyEnvUpdates(content: string, updates: Record<string, string>): string {
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
 * Read an instance env file's raw content. Returns null if it doesn't exist.
 */
export async function readEnvContent(envPath: string): Promise<string | null> {
  try {
    return await fs.readFile(envPath, "utf-8");
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return null;
    }
    throw error;
  }
}

/**
 * Read an instance env file. Returns null if it doesn't exist.
 */
export async function readEnvFile(envPath: string): Promise<Record<string, string> | null> {
  const content = await readEnvContent(envPath);
  return content === null ? null : parseEnvContent(content);
}

/**
 * The env file variables that hold a network configuration
 */
export function networkEnv(network: NetworkConfig): Record<string, string> {
  return {
    ZOO_SUBNET: network.subnet,
    ZOO_PUBLIC_SUBNET: network.publicSubnet,
    ZOO_DNS_IP: network.dnsIP,
    ZOO_CADDY_IP: network.caddyIP,
    ZOO_PROXY_IP: network.proxyIP,
  };
}

/**
 * The subnets saved in an instance env that overlap any of `usedSubnets`
 */
export function findSubnetConflicts(env: Record<string, string>, usedSubnets: string[]): string[] {
  const used = toRanges(usedSubnets);
  return [env.ZOO_SUBNET, env.ZOO_PUBLIC_SUBNET].filter(
    (subnet): subnet is string => Boolean(subnet) && overlaps(subnet, used),
  );
}

/**
 * Pick the instance network: a high-range block in a /16 chosen from the project
 * name (or derived from --ip-base), plus a /30 public subnet
 */
export async function allocateNetwork(
  projectName: string,
  options: NetworkOptions = {},
): Promise<NetworkConfig> {
  let subnet: string;
  let dnsIP: string;
  let caddyIP: string;
  let proxyIP: string;

  const hash = crypto.createHash("md5").update(projectName).digest();
  const used = toRanges(options.usedSubnets ?? (await getDockerSubnets(projectName)));

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
    if (overlaps(subnet, used)) {
      throw new Error(`Subnet ${subnet} (from --ip-base) overlaps an existing Docker network`);
    }

    // Assign consecutive IPs starting from base + 1
    dnsIP = `${octet1}.${octet2}.${octet3}.${lastOctet + 1}`;
    caddyIP = `${octet1}.${octet2}.${octet3}.${lastOctet + 2}`;
    proxyIP = `${octet1}.${octet2}.${octet3}.${lastOctet + 3}`;
  } else {
    // Start from a slot derived from the project name so allocation is stable,
    // then skip /16s already used by other Docker networks
    const count = INSTANCE_SECOND_OCTETS.length;
    const first = hash.readUInt16BE(0) % count;
    const secondOctet = Array.from(
      { length: count },
      (_, i) => INSTANCE_SECOND_OCTETS[(first + i) % count],
    ).find((octet) => !overlaps(`172.${octet}.0.0/16`, used));
    if (secondOctet === undefined) {
      throw new Error(
        "No free 172.x.0.0/16 subnet for a new instance: every candidate overlaps an existing " +
          "Docker network. Remove unused networks or create the instance with --ip-base.",
      );
    }
    subnet = `172.${secondOctet}.0.0/16`;

    // Use high third octet range (240-255) with randomization to avoid conflicts
    const thirdOctet = 240 + (hash[2] % 16);

    dnsIP = `172.${secondOctet}.${thirdOctet}.2`;
    caddyIP = `172.${secondOctet}.${thirdOctet}.3`;
    proxyIP = `172.${secondOctet}.${thirdOctet}.4`;
  }

  const instanceRange = parseCidr(subnet);
  const publicSubnet = allocatePublicSubnet(
    hash.readUInt16BE(4),
    instanceRange ? [...used, instanceRange] : used,
  );

  return { subnet, publicSubnet, dnsIP, caddyIP, proxyIP };
}

/**
 * Content of a new instance env file with a freshly allocated network.
 * ZOO_IP_BASE records a --ip-base so the network is never reallocated.
 */
export async function renderEnvFile(
  projectName: string,
  options: EnvFileOptions = {},
): Promise<{ content: string; network: NetworkConfig }> {
  const network = await allocateNetwork(projectName, options);
  const networkLines = Object.entries(networkEnv(network)).map(([key, value]) => `${key}=${value}`);
  if (options.ipBase) {
    networkLines.push(`ZOO_IP_BASE=${options.ipBase}`);
  }

  const content = `# Auto-generated environment file for Zoo instance
# Project: ${projectName}

# Network configuration
${networkLines.join("\n")}
${options.port ? `ZOO_PROXY_PORT=${options.port}` : ""}

# Proxy authentication (optional, leave empty for no auth)
PROXY_USER=
PROXY_PASS=

# This file is used when restarting containers manually
# to ensure the same IP assignments are preserved
`;

  return { content: applyEnvUpdates(content, options.env ?? {}), network };
}
