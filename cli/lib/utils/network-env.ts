import crypto from "node:crypto";
import fs from "node:fs/promises";
import { checkDocker, execCommand } from "./docker";
import { CliError, errorMessage } from "./errors";

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

// Instance subnets are /16s, identified by their first two octets. The preferred ones
// are the 172.17-172.31 /16s of Docker's default address pools, except 172.20-172.23
// (the dev and fresh environments). Docker also hands those to every network created
// without a subnet, so on a busy machine all of them can be taken; the fallbacks are
// outside Docker's default pools (172.17.0.0/16-172.31.0.0/16, and 192.168.0.0/16 in
// /20s). 172.16.0.0/16, also outside them, is reserved for the instances' /30 public subnets.
const PREFERRED_PREFIXES = [17, 18, 19, 24, 25, 26, 27, 28, 29, 30, 31].map((b) => `172.${b}`);
const FALLBACK_PREFIXES = Array.from({ length: 32 }, (_, i) => `10.${200 + i}`);
const INSTANCE_SUBNETS = [...PREFERRED_PREFIXES, ...FALLBACK_PREFIXES].map(
  (prefix) => `${prefix}.0.0/16`,
);
const PUBLIC_BLOCK_START = 172 * 2 ** 24 + 16 * 2 ** 16;
const PUBLIC_BLOCK_SLOTS = 2 ** 16 / 4;

interface IPv4Range {
  start: number;
  end: number;
}

function parseIPv4(ip: string): number | null {
  const match = ip.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
  if (!match) {
    return null;
  }
  const octets = match.slice(1).map(Number);
  if (octets.some((octet) => octet > 255)) {
    return null;
  }
  return octets.reduce((address, octet) => address * 256 + octet, 0);
}

function parseCidr(cidr: string): IPv4Range | null {
  const match = cidr.match(/^([\d.]+)\/(\d+)$/);
  const address = match && parseIPv4(match[1]);
  const bits = Number(match?.[2]);
  if (address === null || bits > 32) {
    return null;
  }
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

interface DockerNetwork {
  Labels?: Record<string, string> | null;
  IPAM?: { Config?: Array<{ Subnet?: string }> | null };
}

const NETWORK_INSPECT_ATTEMPTS = 3;

/**
 * Subnets of existing Docker networks, other than the project's own. Empty when Docker
 * is unavailable, since there is nothing to avoid then.
 */
export async function getDockerSubnets(projectName: string): Promise<string[]> {
  for (let attempt = 1; ; attempt++) {
    let networkIds: string[];
    try {
      const { stdout } = await execCommand("docker", ["network", "ls", "-q"]);
      networkIds = stdout.split("\n").filter(Boolean);
    } catch (error) {
      if (await checkDocker()) {
        throw error;
      }
      return [];
    }
    if (networkIds.length === 0) {
      return [];
    }

    try {
      const { stdout } = await execCommand("docker", ["network", "inspect", ...networkIds]);
      const networks: DockerNetwork[] = JSON.parse(stdout);
      return networks
        .filter((network) => network.Labels?.["com.docker.compose.project"] !== projectName)
        .flatMap((network) => network.IPAM?.Config ?? [])
        .map((config) => config.Subnet)
        .filter((subnet): subnet is string => Boolean(subnet));
    } catch (error) {
      // The whole inspect fails if a network was removed after `ls`, so list them again
      if (attempt === NETWORK_INSPECT_ATTEMPTS) {
        throw new Error(`Could not inspect Docker networks: ${errorMessage(error)}`);
      }
    }
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
 * and appending new ones at the end under `comment`.
 */
export function applyEnvUpdates(
  content: string,
  updates: Record<string, string>,
  comment = "# Set with --set-env",
): string {
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
    lines.push("", comment);
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

function isPublicSubnet(cidr: string | undefined): boolean {
  const range = cidr ? parseCidr(cidr) : null;
  return (
    range !== null &&
    cidr === `${formatIPv4(range.start)}/30` &&
    range.start >= PUBLIC_BLOCK_START &&
    range.start < PUBLIC_BLOCK_START + PUBLIC_BLOCK_SLOTS * 4
  );
}

/**
 * Whether a saved network is one allocateNetwork picks: an instance /16 holding the
 * service IPs, plus a /30 from the public block. An .env from an older CLI can have
 * other ranges, or no ZOO_PUBLIC_SUBNET, so compose falls back to the dev environment's.
 */
export function isAllocatedNetwork(env: Record<string, string>): boolean {
  const subnet = INSTANCE_SUBNETS.includes(env.ZOO_SUBNET) ? parseCidr(env.ZOO_SUBNET) : null;
  const inSubnet = (ip: string | undefined) => {
    const address = ip ? parseIPv4(ip) : null;
    return subnet !== null && address !== null && address >= subnet.start && address <= subnet.end;
  };
  return (
    [env.ZOO_DNS_IP, env.ZOO_CADDY_IP, env.ZOO_PROXY_IP].every(inSubnet) &&
    isPublicSubnet(env.ZOO_PUBLIC_SUBNET)
  );
}

/**
 * The --ip-base an older CLI's .env was created with; those CLIs didn't record it. They
 * allocated 172.x /16s with the service IPs at .2-.4 in a third octet of 240-255, so any
 * other /16 holding three consecutive service IPs came from --ip-base.
 */
export function legacyIpBase(env: Record<string, string>): string | null {
  const subnet = env.ZOO_SUBNET?.endsWith("/16") ? parseCidr(env.ZOO_SUBNET) : null;
  const [dns, caddy, proxy] = [env.ZOO_DNS_IP, env.ZOO_CADDY_IP, env.ZOO_PROXY_IP].map((ip) =>
    ip ? parseIPv4(ip) : null,
  );
  if (
    subnet === null ||
    dns === null ||
    caddy !== dns + 1 ||
    proxy !== dns + 2 ||
    dns - 1 < subnet.start ||
    proxy > subnet.end
  ) {
    return null;
  }
  const allocated =
    env.ZOO_SUBNET.startsWith("172.") && Math.floor(dns / 256) % 256 >= 240 && dns % 256 === 2;
  return allocated ? null : formatIPv4(dns - 1);
}

/**
 * The --ip-base a saved network came from, if any: its ZOO_IP_BASE or, in an older
 * CLI's .env, the one legacyIpBase finds
 */
export function savedIpBase(env: Record<string, string>): string | null {
  return env.ZOO_IP_BASE || (isAllocatedNetwork(env) ? null : legacyIpBase(env));
}

/**
 * A free /30 public subnet for the project, the one allocateNetwork would pick
 */
export function allocateProjectPublicSubnet(
  projectName: string,
  usedSubnets: string[],
  instanceSubnet: string,
): string {
  const hash = crypto.createHash("md5").update(projectName).digest();
  return allocatePublicSubnet(hash.readUInt16BE(4), toRanges([...usedSubnets, instanceSubnet]));
}

const PRIVATE_RANGES = toRanges(["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]);

/**
 * Parse an --ip-base. Its /16 becomes the instance subnet and base + 1, 2, 3 the DNS, Caddy
 * and proxy IPs. Those must be host addresses of the /16: after its .0.0 network address and
 * the .0.1 Docker gives the gateway, and before its .255.255 broadcast address.
 */
export function parseIpBase(ipBase: string): number {
  const invalid = (hint: string) => new CliError(`Invalid --ip-base: "${ipBase}"`, { hint });
  const base = parseIPv4(ipBase);
  if (base === null) {
    throw invalid("Expected an IPv4 address such as 172.30.100.1");
  }
  if (!PRIVATE_RANGES.some((range) => base >= range.start && base <= range.end)) {
    throw invalid("Use a private address, in 10.0.0.0/8, 172.16.0.0/12 or 192.168.0.0/16");
  }
  if (base >= PUBLIC_BLOCK_START && base < PUBLIC_BLOCK_START + 2 ** 16) {
    throw invalid("172.16.0.0/16 is reserved for the instances' public subnets");
  }
  const lastOctet = base % 256;
  const broadcast = base - (base % 2 ** 16) + 2 ** 16 - 1;
  if (lastOctet < 1 || lastOctet > 252 || base + 3 >= broadcast) {
    throw invalid(
      "base + 1, 2 and 3 must be host addresses of its /16, so its last octet must be 1-252 (1-251 in x.x.255.x)",
    );
  }
  return base;
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
    const base = parseIpBase(options.ipBase);
    subnet = `${formatIPv4(base - (base % 2 ** 16))}/16`;
    if (overlaps(subnet, used)) {
      throw new Error(`Subnet ${subnet} (from --ip-base) overlaps an existing Docker network`);
    }
    [dnsIP, caddyIP, proxyIP] = [1, 2, 3].map((offset) => formatIPv4(base + offset));
  } else {
    // Start from a slot derived from the project name so allocation is stable, then
    // skip /16s already used by other Docker networks, trying the fallbacks last
    const slot = hash.readUInt16BE(0);
    const prefix = [PREFERRED_PREFIXES, FALLBACK_PREFIXES]
      .flatMap((prefixes) => prefixes.map((_, i) => prefixes[(slot + i) % prefixes.length]))
      .find((candidate) => !overlaps(`${candidate}.0.0/16`, used));
    if (prefix === undefined) {
      throw new CliError(
        `No free subnet for a new instance: all ${INSTANCE_SUBNETS.length} candidate /16s overlap existing Docker networks`,
        {
          hint:
            'Remove unused Docker networks, or pick a free subnet with "the_zoo create --ip-base <ip>" ' +
            'and start that instance with "the_zoo start --instance <id>"',
        },
      );
    }
    subnet = `${prefix}.0.0/16`;

    // Use high third octet range (240-255) with randomization to avoid conflicts
    const thirdOctet = 240 + (hash[2] % 16);

    dnsIP = `${prefix}.${thirdOctet}.2`;
    caddyIP = `${prefix}.${thirdOctet}.3`;
    proxyIP = `${prefix}.${thirdOctet}.4`;
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

# The instance's compose project, also for docker compose commands run by hand
COMPOSE_PROJECT_NAME=${projectName}

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
