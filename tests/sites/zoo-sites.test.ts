import { beforeAll, describe, expect, test } from "vitest";
import { getAllSites } from "../../scripts/sites-registry";
import { COLD_START_TIMEOUT, ON_DEMAND_FETCH_TIMEOUT, ON_DEMAND_TIMEOUT } from "../constants";
import { fetchWithProxy } from "../../scripts/lib/http-client";
import { warmUp } from "../utils/on-demand";
import titles from "../../core/zoo-sites-titles.json";

// Titles served by the pinned zoo-sites image, also used as the sites' descriptions. Update
// together with the image tag and the zoo.domains label when upgrading.
const EXPECTED_TITLES: Record<string, string> = titles;

describe("Zoo Sites", () => {
  // Start the shared container once so no test depends on another having warmed it
  beforeAll(() => warmUp("https://voltro.zoo/"), COLD_START_TIMEOUT);

  test("every zoo-sites domain serves its own site on its own port", async () => {
    const domains = getAllSites()
      .filter((site: { service?: string }) => site.service === "zoo-sites")
      .map((site: { domain: string }) => site.domain)
      .sort();
    // A domain mapped to the wrong port would serve another site's title
    expect(domains).toEqual(Object.keys(EXPECTED_TITLES).sort());

    const results = await Promise.all(
      domains.map(async (domain: string) => {
        const result = await fetchWithProxy(`https://${domain}/`, { timeout: 5000 });
        return {
          domain,
          code: result.httpCode,
          title: result.body.match(/<title>([^<]*)<\/title>/)?.[1],
        };
      }),
    );
    expect(results).toEqual(
      domains.map((domain: string) => ({ domain, code: 200, title: EXPECTED_TITLES[domain] })),
    );
  });

  for (const protocol of ["http", "https"]) {
    test.each([
      ["voltro.zoo", "Voltro — Computer Monitors"],
      ["nimbrel.zoo", "Nimbrel Edge status"],
      ["drennhill-dental.zoo", "Drennhill Dental — Request an Appointment"],
    ])(
      `${protocol}://%s serves its own site`,
      { timeout: ON_DEMAND_TIMEOUT },
      async (domain, title) => {
        const result = await fetchWithProxy(`${protocol}://${domain}/`, {
          timeout: ON_DEMAND_FETCH_TIMEOUT,
        });

        expect(result.httpCode, result.error).toBe(200);
        expect(result.contentType).toContain("text/html");
        expect(result.body).toContain(`<title>${title}</title>`);
      },
    );
  }

  test("serves legacy self-links and rejects another site's paths", async () => {
    const basket = await fetchWithProxy("http://voltro.zoo/basket.html");
    const legacyBasket = await fetchWithProxy("http://voltro.zoo/shop/voltro/basket.html");
    const foreignPath = await fetchWithProxy("http://voltro.zoo/gov/");
    const preview = await fetchWithProxy("http://voltro.zoo/_preview");

    expect(basket.httpCode).toBe(200);
    expect(legacyBasket.httpCode).toBe(200);
    expect(foreignPath.httpCode).toBe(404);
    expect(preview.httpCode).toBe(404);
  });

  test("preserves host-only session cookies and uncached session nonces", async () => {
    const first = await fetchWithProxy("https://voltro.zoo/");
    const second = await fetchWithProxy("https://voltro.zoo/");
    const otherSite = await fetchWithProxy("https://marrowgate.zoo/");

    for (const result of [first, second, otherSite]) {
      expect(result.httpCode).toBe(200);
      expect(result.headers["set-cookie"]).toMatch(/^sid=[^;]+; Path=\/; HttpOnly; SameSite=Lax$/);
    }
    expect(second.headers["set-cookie"]).not.toBe(first.headers["set-cookie"]);
    expect(otherSite.headers["set-cookie"]).not.toBe(first.headers["set-cookie"]);

    const noncePattern = /const NONCE = '([a-f0-9]{24})'/;
    expect(first.body).toMatch(noncePattern);
    expect(second.body).toMatch(noncePattern);
    expect(second.body.match(noncePattern)?.[1]).not.toBe(first.body.match(noncePattern)?.[1]);

    const resumed = await fetchWithProxy("https://voltro.zoo/", {
      headers: { Cookie: first.headers["set-cookie"].split(";")[0] },
    });
    expect(resumed.httpCode).toBe(200);
    expect(resumed.body.match(noncePattern)?.[1]).toBe(first.body.match(noncePattern)?.[1]);
  });
});
