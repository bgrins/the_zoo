import type { TestProject } from "vitest/node";
import { fetchWithProxy } from "../scripts/lib/http-client";
import { loadSites, onDemandServiceSites, type Site } from "../scripts/lib/sites";
import { isServiceAvailable } from "./utils/available";
import { type ContainerState, serviceState, serviceStatuses } from "./utils/containers";

// Caddy gives an on-demand container 90s to become ready
const WARM_UP_TIMEOUT = 120_000;

// Started by the cold-start probe instead of warmed up. check.yml reads this line to leave
// the service stopped in CI.
export const COLD_START_SERVICE = "microbin";

export interface ColdStart {
  site: string;
  before?: ContainerState;
  httpCode?: number;
  error?: string;
  seconds?: number;
  after?: ContainerState;
}

/** The first request the run made to an on-demand app */
export interface WarmUp {
  site: string;
  service: string;
  heavy: boolean;
  // The container's status before the request: anything but running means a cold start
  status: string;
  httpCode: number;
  error?: string;
  seconds: number;
}

declare module "vitest" {
  export interface ProvidedContext {
    coldStart: ColdStart;
    warmUps: WarmUp[];
  }
}

async function request(site: Site) {
  const result = await fetchWithProxy(`https://${site.domain}/`, { timeout: WARM_UP_TIMEOUT });
  const seconds = Number(result.timeTotal?.toFixed(1));
  console.log(
    `[warm-up] ${site.domain} (${site.service}): ${result.error ?? `HTTP ${result.httpCode}`} after ${seconds}s`,
  );
  return { httpCode: result.httpCode, error: result.error, seconds };
}

/**
 * Start every on-demand app once, in parallel, so no test pays for a cold start within its
 * own timeout. One app is left for a probe of the on-demand start itself: its state before
 * and after a first request, taken here because other test files request it too.
 */
export default async function setup(project: TestProject) {
  const sites = onDemandServiceSites(loadSites()).filter((site) =>
    isServiceAvailable(site.service),
  );
  const coldSite = sites.find((site) => site.service === COLD_START_SERVICE);
  if (!coldSite) {
    throw new Error(`SITES.yaml has no on-demand ${COLD_START_SERVICE} site`);
  }
  const coldStart: ColdStart = { site: coldSite.domain };
  const warmUps: WarmUp[] = [];
  try {
    const statuses = serviceStatuses();
    const warmUp = async (site: Site, status: string) => {
      const result = await request(site);
      warmUps.push({
        site: site.domain,
        service: site.service,
        heavy: site.heavy ?? false,
        status,
        ...result,
      });
      return result;
    };
    const probe = async () => {
      coldStart.before = serviceState(COLD_START_SERVICE);
      if (coldStart.before && coldStart.before.status !== "running") {
        Object.assign(coldStart, await warmUp(coldSite, coldStart.before.status));
        coldStart.after = serviceState(COLD_START_SERVICE);
      }
    };

    for (const site of sites.filter((site) => !statuses.has(site.service))) {
      console.log(`[warm-up] ${site.domain} (${site.service}): no container, skipped`);
    }
    const warmed = sites.filter((site) => site !== coldSite && statuses.has(site.service));
    await Promise.all([
      probe(),
      ...warmed.map((site) => warmUp(site, statuses.get(site.service) as string)),
    ]);
  } finally {
    project.provide("coldStart", coldStart);
    project.provide("warmUps", warmUps);
  }
}
