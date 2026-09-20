/**
 * Matomo site IDs for shared.js, from the sites in the analytics golden seed.
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

export const ANALYTICS_SEED_PATH = path.join(ROOT, "core/mysql/sql/analytics_seed.sql");
export const SHARED_JS_PATH = path.join(ROOT, "sites/static/performance.zoo/dist/shared.js");

// shared.js runs on performance.zoo and reports to analytics.zoo, so tracking either would
// loop; the others serve APIs or images, not pages
export const UNTRACKED_DOMAINS = new Set([
  "performance.zoo",
  "analytics.zoo",
  "admin.auth.zoo",
  "mail-api.zoo",
  "secure.gravatar.com",
]);

/** Main URL hostname → idsite for every site in the seed's matomo_site table */
export function matomoSiteIds(seedSql = fs.readFileSync(ANALYTICS_SEED_PATH, "latin1")) {
  const insert = seedSql.split("\n").find((line) => line.startsWith("INSERT INTO `matomo_site` "));
  if (!insert) {
    throw new Error("No matomo_site rows in the analytics seed");
  }
  const ids = new Map<string, number>();
  // Each row starts (idsite,'name','main_url',...
  for (const [, id, mainUrl] of insert.matchAll(/\((\d+),'(?:[^'\\]|\\.)*','((?:[^'\\]|\\.)*)'/g)) {
    if (mainUrl) {
      ids.set(new URL(mainUrl).hostname, Number(id));
    }
  }
  return ids;
}

/** SITE_IDS for the tracked domains, and the tracked domains Matomo has no site for */
export function siteIdsFor(domains: string[], ids = matomoSiteIds()) {
  const tracked = domains.filter((domain) => !UNTRACKED_DOMAINS.has(domain)).sort();
  return {
    siteIds: Object.fromEntries(
      tracked.filter((domain) => ids.has(domain)).map((domain) => [domain, ids.get(domain)]),
    ) as Record<string, number>,
    missing: tracked.filter((domain) => !ids.has(domain)),
  };
}

/** shared.js with its SITE_IDS block replaced */
export function renderSharedJs(sharedJs: string, siteIds: Record<string, number>): string {
  const entries = Object.entries(siteIds)
    .map(([domain, id]) => `    '${domain}': ${id},\n`)
    .join("");
  const block = `  // SITE_IDS:BEGIN\n  const SITE_IDS = {\n${entries}  };\n  // SITE_IDS:END`;
  const updated = sharedJs.replace(/ {2}\/\/ SITE_IDS:BEGIN\n[\s\S]*?\/\/ SITE_IDS:END/, block);
  if (updated === sharedJs && !sharedJs.includes(block)) {
    throw new Error("shared.js has no SITE_IDS:BEGIN/END block");
  }
  return updated;
}
