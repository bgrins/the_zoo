import { describe, expect, test } from "vitest";
import { fetchWithProxy } from "../utils/http-client";

// These domains are intercepted by DNS (pointing to Caddy) and swallowed with a 200 response.
// Apps like Mattermost make requests to these telemetry/analytics endpoints, and they
// need to succeed (not error) even though there's no internet access in the zoo.
const swallowedDomains = ["pdat.matterlytics.com", "api.rudderlabs.com"];

describe("Swallowed external domains", () => {
  for (const domain of swallowedDomains) {
    test.concurrent(`${domain} should return 200 via HTTPS`, async () => {
      const result = await fetchWithProxy(`https://${domain}/`);
      expect(result.success, `Failed to reach ${domain}: ${result.error}`).toBe(true);
      expect(result.httpCode).toBe(200);
    });

    test.concurrent(`${domain} should return 200 via HTTP`, async () => {
      const result = await fetchWithProxy(`http://${domain}/`);
      expect(result.success, `Failed to reach ${domain}: ${result.error}`).toBe(true);
      expect(result.httpCode).toBe(200);
    });

    test.concurrent(`${domain} should have CORS headers`, async () => {
      const result = await fetchWithProxy(`https://${domain}/`);
      expect(result.success, `Failed to reach ${domain}: ${result.error}`).toBe(true);
      expect(result.headers["access-control-allow-origin"]).toBe("*");
    });
  }
});
