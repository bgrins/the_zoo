#!/usr/bin/env -S npx tsx

/**
 * Prints, as JSON, the Matomo visits (with their actions) tagged with a run ID: shared.js
 * stores the zoo_run_id cookie as custom dimension 2.
 *
 *   npx tsx scripts/analytics-export-run.ts <run-id> [date]
 *
 * date is a Matomo range such as last2 (the default) or 2026-09-01,today.
 */

import { fetch, ProxyAgent } from "undici";
import { PROXY_URL } from "./lib/proxy";

// analytics_user's API token, created in core/mysql/sql/analytics_seed.sql
const TOKEN = "548352a992deec98a8a2af37460fdf71";
const API_URL = "https://analytics.zoo/index.php";

const dispatcher = new ProxyAgent({
  uri: PROXY_URL,
  requestTls: { rejectUnauthorized: false },
});

async function api(method: string, params: Record<string, string> = {}): Promise<any> {
  const body = new URLSearchParams({ module: "API", method, format: "json", token_auth: TOKEN });
  for (const [key, value] of Object.entries(params)) {
    body.set(key, value);
  }
  const response = await fetch(API_URL, { method: "POST", body, dispatcher });
  const data: any = await response.json();
  if (data?.result === "error") {
    throw new Error(`${method}: ${data.message}`);
  }
  return data;
}

const [runId, date = "last2"] = process.argv.slice(2);
if (!runId) {
  console.error("Usage: npx tsx scripts/analytics-export-run.ts <run-id> [date]");
  process.exit(1);
}

// Custom dimension segments only work per site, not with idSite=all
const visits: any[] = [];
for (const idSite of (await api("SitesManager.getSitesIdWithAtLeastViewAccess")) as number[]) {
  visits.push(
    ...(await api("Live.getLastVisitsDetails", {
      idSite: String(idSite),
      period: "range",
      date,
      segment: `dimension2==${encodeURIComponent(runId)}`,
      filter_limit: "-1",
    })),
  );
}
visits.sort((a, b) => a.firstActionTimestamp - b.firstActionTimestamp);
console.log(JSON.stringify(visits, null, 2));
