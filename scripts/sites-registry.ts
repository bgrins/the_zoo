#!/usr/bin/env -S npx tsx

/**
 * Sites Registry
 * Shared module for discovering and managing zoo sites
 *
 * Returns sites from SITES.yaml with computed health URLs
 */

import fs from "node:fs";
import path from "node:path";
import yaml from "yaml";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const CUSTOM_HEALTH_PATHS: Record<string, string> = {
  "admin.auth.zoo": "/health/ready",
  "mail-api.zoo": "/api",
};

export interface Site {
  domain: string;
  type: "static" | "proxy";
  source: "directory" | "docker-compose";
  port?: number;
  service?: string;
  onDemand?: boolean;
  httpHealthUrl: string;
  httpsHealthUrl: string;
}

/**
 * Get all zoo sites from SITES.yaml
 */
export function getAllSites() {
  const sitesFile = path.join(__dirname, "..", "core", "SITES.yaml");

  if (!fs.existsSync(sitesFile)) {
    throw new Error("SITES.yaml not found. Run 'npm run generate-config' to generate it.");
  }

  try {
    const content = fs.readFileSync(sitesFile, "utf8");
    const data = yaml.parse(content);

    if (!data.sites || !Array.isArray(data.sites)) {
      throw new Error("SITES.yaml has invalid format - missing sites array");
    }

    const sites = data.sites.map((site: any) => {
      const healthPath = CUSTOM_HEALTH_PATHS[site.domain] || "";
      const httpHealthUrl = `http://${site.domain}${healthPath}`;
      const httpsHealthUrl = `https://${site.domain}${healthPath}`;

      return {
        domain: site.domain,
        type: site.type,
        port: site.port ? parseInt(site.port, 10) : undefined,
        service: site.service,
        onDemand: site.onDemand,
        httpHealthUrl,
        httpsHealthUrl,
        // Keep these for backward compatibility if needed
        source: "docker-compose" as const,
        backend: site.port ? `${site.service}:${site.port}` : undefined,
        // Additional metadata from SITES.yaml
        description: site.description,
        icon: site.icon,
        hasOAuth: site.hasOAuth,
        httpsOnly: site.httpsOnly,
      };
    });

    return sites.sort((a: any, b: any) => a.domain.localeCompare(b.domain));
  } catch (error) {
    console.error("Failed to parse SITES.yaml:", error);
    throw error;
  }
}
