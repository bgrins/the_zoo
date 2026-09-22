import fs from "node:fs";
import { describe, expect, it } from "vitest";
import { renderSharedJs, SHARED_JS_PATH, siteIdsFor } from "../../scripts/analytics-sites";
import { getAllSites } from "../../scripts/sites-registry";

describe("Analytics sites", () => {
  const domains = getAllSites().map((site: { domain: string }) => site.domain);

  it("every zoo site with pages has a Matomo site", () => {
    expect(siteIdsFor(domains).missing).toEqual([]);
  });

  it("shared.js has the generated SITE_IDS", () => {
    const sharedJs = fs.readFileSync(SHARED_JS_PATH, "utf8");
    expect(renderSharedJs(sharedJs, siteIdsFor(domains).siteIds)).toBe(sharedJs);
  });
});
