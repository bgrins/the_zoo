import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import yaml from "yaml";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

/** A site in core/SITES.yaml, which scripts/generate-config.ts writes */
export interface Site {
  domain: string;
  type: "proxy" | "static";
  port: number;
  service: string;
  description?: string;
  icon?: string;
  hasOAuth: boolean;
  httpsOnly?: boolean;
  onDemand?: boolean;
  heavy?: boolean;
}

/** The sites in `zooRoot`/core/SITES.yaml, sorted by domain */
export function loadSites(zooRoot = ROOT): Site[] {
  const file = path.join(zooRoot, "core/SITES.yaml");
  if (!fs.existsSync(file)) {
    throw new Error(`${file} not found. Run 'npm run generate-config' to generate it.`);
  }
  const { sites } = yaml.parse(fs.readFileSync(file, "utf8")) as { sites?: Site[] };
  if (!Array.isArray(sites)) {
    throw new Error(`${file} has no sites list`);
  }
  return sites;
}

// Infrastructure rather than apps: home.zoo doesn't list them and screenshots skip them
const SYSTEM_DOMAINS = new Set([
  "admin.auth.zoo",
  "mail-api.zoo",
  "secure.gravatar.com",
  "status.zoo",
]);

export function isSystemSite(site: Site): boolean {
  return SYSTEM_DOMAINS.has(site.domain);
}

/** The first site of each on-demand service, whose first request starts its container */
export function onDemandServiceSites(sites: Site[]): Site[] {
  const services = new Set<string>();
  return sites.filter((site) => {
    if (!site.onDemand || services.has(site.service)) {
      return false;
    }
    services.add(site.service);
    return true;
  });
}
