#!/usr/bin/env -S npx tsx

/**
 * Docker Compose Utilities
 * Shared utilities for parsing docker-compose.yaml
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Type definitions for Docker Compose structures

export interface DockerComposeHealthcheck {
  test: string | string[];
  interval?: string;
  timeout?: string;
  retries?: number;
  start_period?: string;
}

export interface DockerComposeNetwork {
  ipv4_address?: string;
}

export interface DockerComposeService {
  build?:
    | string
    | {
        context: string;
        dockerfile?: string;
      };
  image?: string;
  restart?: string;
  environment?: string[] | Record<string, string | number>;
  volumes?: string[];
  networks?: Record<string, DockerComposeNetwork> | string[];
  healthcheck?: DockerComposeHealthcheck;
  labels?: string[] | Record<string, string>;
  depends_on?: string[] | Record<string, { condition: string }>;
  ports?: (string | number)[];
  expose?: (string | number)[];
  dns?: string[];
  profiles?: string[];
  container_name?: string;
  command?: string | string[];
  entrypoint?: string | string[];
}

export interface DockerComposeNetworkConfig {
  driver?: string;
  ipam?: {
    config?: Array<{
      subnet: string;
    }>;
  };
}

export interface DockerComposeConfig {
  version?: string;
  services: Record<string, DockerComposeService>;
  networks?: Record<string, DockerComposeNetworkConfig>;
  volumes?: Record<string, any>;
}

// Cache for parsed docker-compose configuration
let parseCache: { path: string; config: DockerComposeConfig } | null = null;

/**
 * Read and parse docker-compose.yaml with expanded YAML anchors
 * Always returns the fully expanded configuration with all profiles included
 * @param customPath - Optional custom path to docker-compose.yaml
 */
export function parseDockerCompose(customPath?: string): DockerComposeConfig {
  const composePath = customPath
    ? path.resolve(customPath)
    : path.join(__dirname, "..", "docker-compose.yaml");
  if (!fs.existsSync(composePath)) {
    throw new Error(`docker-compose.yaml not found at ${composePath}`);
  }

  // Return cached result if we've already parsed this path
  if (parseCache && parseCache.path === composePath) {
    return parseCache.config;
  }

  // Always use docker compose config to get expanded configuration
  const result = execSync("docker compose --profile '*' config --format json", {
    encoding: "utf8",
    cwd: path.dirname(composePath),
  });
  const config = JSON.parse(result) as DockerComposeConfig;

  // Cache the result
  parseCache = { path: composePath, config };

  return config;
}

/**
 * Get services from docker-compose.yaml
 */
export function getDockerComposeServices() {
  const compose = parseDockerCompose();
  return compose.services || {};
}

/**
 * Get raw service configuration including all properties like profiles
 */
export function getRawServiceConfig(serviceName: string): DockerComposeService | undefined {
  try {
    const compose = parseDockerCompose();
    return compose.services?.[serviceName];
  } catch (error) {
    console.error("Failed to get service config:", error);
    return undefined;
  }
}

/**
 * Check if a service has on-demand profile
 */
export function isServiceOnDemand(serviceName: string): boolean {
  const config = getRawServiceConfig(serviceName);
  return config?.profiles?.includes("on-demand") || false;
}

/**
 * Check if a service has heavy profile (large images not suitable for CI)
 */
export function isServiceHeavy(serviceName: string): boolean {
  const config = getRawServiceConfig(serviceName);
  return config?.profiles?.includes("heavy") || false;
}

/**
 * Extract port from service configuration
 * This is the single source of truth for port extraction logic
 */
export function extractPortFromServiceConfig(
  serviceConfig: DockerComposeService | undefined,
): string {
  if (!serviceConfig) return "3000";

  // 1. Check environment variables (highest priority)
  if (serviceConfig.environment) {
    // Handle array format
    if (Array.isArray(serviceConfig.environment)) {
      const portEnv = serviceConfig.environment.find((e) => {
        if (typeof e === "string") {
          return e.startsWith("PORT=");
        }
        return false;
      });

      if (portEnv) {
        return portEnv.split("=")[1];
      }
    }
    // Handle object format
    else if (typeof serviceConfig.environment === "object") {
      if (serviceConfig.environment.PORT) {
        return serviceConfig.environment.PORT.toString();
      }
    }
  }

  // 2. Check expose directive
  if (
    serviceConfig.expose &&
    Array.isArray(serviceConfig.expose) &&
    serviceConfig.expose.length > 0
  ) {
    return serviceConfig.expose[0].toString();
  }

  // 3. Check ports mapping
  if (serviceConfig.ports && Array.isArray(serviceConfig.ports) && serviceConfig.ports.length > 0) {
    const portMapping = serviceConfig.ports[0];
    if (typeof portMapping === "string") {
      // Handle formats like "8080:80", "8080:80/tcp", "80"
      const parts = portMapping.split(":");
      const targetPort = parts[parts.length - 1];
      return targetPort.split("/")[0]; // Remove protocol suffix if present
    } else if (typeof portMapping === "number") {
      return portMapping.toString();
    }
  }

  // 4. Default fallback
  return "3000";
}

/**
 * Get port for a specific service by name
 */
export function getServicePort(serviceName: string): string {
  const services = getDockerComposeServices();
  const serviceConfig = services[serviceName];
  return extractPortFromServiceConfig(serviceConfig);
}

/**
 * Get all services with their ports
 */
export function getAllServicesWithPorts(): Record<string, any> {
  const services = getDockerComposeServices();
  const result: Record<string, any> = {};

  for (const [serviceName, serviceConfig] of Object.entries(services)) {
    result[serviceName] = {
      port: extractPortFromServiceConfig(serviceConfig),
      ...serviceConfig,
    };
  }

  return result;
}
