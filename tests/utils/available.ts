import { loadSites } from "../../scripts/lib/sites";

const sites = loadSites();
const serviceOf = new Map(sites.map((site) => [site.domain, site.service]));
const heavyServices = new Set(sites.filter((site) => site.heavy).map((site) => site.service));

/**
 * Whether this run has the compose service. CI never creates the heavy profile's apps
 * (postmill, onestopshop), whose images add ~20GB, so Caddy answers them with a 503.
 */
export function isServiceAvailable(service: string): boolean {
  return !(process.env.CI === "true" && heavyServices.has(service));
}

/** Whether this run serves the site `url` is on */
export function isUrlAvailable(url: string): boolean {
  const service = serviceOf.get(new URL(url).hostname);
  return service === undefined || isServiceAvailable(service);
}
