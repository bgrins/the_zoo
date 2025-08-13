import { execSync } from "node:child_process";

/**
 * Get the DNS IP address for Zoo services
 * Dynamically probes the Docker container or uses environment variable
 */
export function getZooDnsIp(): string {
  // First check environment variable
  if (process.env.ZOO_DNS_IP) {
    return process.env.ZOO_DNS_IP;
  }

  try {
    // Get the coredns container name dynamically using docker ps with label filter
    const containerName = execSync(
      'docker ps --filter "label=com.docker.compose.service=coredns" --format "{{.Names}}" | head -1',
      { encoding: "utf8" },
    ).trim();

    if (!containerName) {
      throw new Error("CoreDNS container not found. Make sure the Zoo environment is running.");
    }

    // Get the IP address of the coredns container
    const ip = execSync(
      `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${containerName}`,
      { encoding: "utf8" },
    ).trim();

    if (!ip || !ip.match(/^\d+\.\d+\.\d+\.\d+$/)) {
      throw new Error(`Invalid IP address retrieved for CoreDNS container: ${ip}`);
    }

    return ip;
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`Failed to get DNS IP: ${error.message}`);
    }
    throw new Error("Failed to get DNS IP: Unknown error");
  }
}
