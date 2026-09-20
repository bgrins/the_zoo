/**
 * The sites in core/SITES.yaml with the URLs that tests check their health at
 */

import { loadSites, type Site as SiteConfig } from "./lib/sites";

const CUSTOM_HEALTH_PATHS: Record<string, string> = {
  "admin.auth.zoo": "/health/ready",
  "mail-api.zoo": "/api",
};

export interface Site extends SiteConfig {
  httpHealthUrl: string;
  httpsHealthUrl: string;
}

export function getAllSites(): Site[] {
  return loadSites().map((site) => {
    const healthPath = CUSTOM_HEALTH_PATHS[site.domain] || "";
    return {
      ...site,
      httpHealthUrl: `http://${site.domain}${healthPath}`,
      httpsHealthUrl: `https://${site.domain}${healthPath}`,
    };
  });
}
