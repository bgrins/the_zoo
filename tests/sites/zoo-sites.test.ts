import { describe, expect, test } from "vitest";
import { ON_DEMAND_TIMEOUT } from "../constants";
import { fetchWithProxy } from "../utils/http-client";

describe("Zoo Sites", () => {
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
          timeout: ON_DEMAND_TIMEOUT,
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
