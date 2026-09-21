import { describe, expect, test } from "vitest";
import { getAllSites } from "../../scripts/sites-registry";
import { COLD_START_TIMEOUT } from "../constants";
import { isUrlAvailable } from "../utils/available";
import { fetchWithProxy } from "../../scripts/lib/http-client";

// Pages must be byte-for-byte identical across fetches once two things are normalized: the
// order of Gitea's hidden icon definitions, and these values that change with every response,
// which are masked wherever they appear in either copy:
const RANDOM_TOKENS = [
  // Gitea's CSRF token, repeated in <body hx-headers>
  /csrfToken: '([^']+)'/g,
  // Miniflux's CSRF token
  /data-csrf-token="([^"]+)"/g,
  // Form tokens: Miniflux (csrf), phpMyAdmin (token), Matomo (form_nonce)
  /name="(?:csrf|token|form_nonce)"[^>]*? value="([^"]+)"/g,
  // phpMyAdmin's token in its inline config
  /[,{]token:"([0-9a-f]+)"/g,
  // Content-Security-Policy script nonces (SnappyMail)
  /\bnonce="([^"]+)"/g,
  // zoo-sites' per-page session nonce, which some pages also put in links
  /\b[A-Z_]*NONCE = '([0-9a-f]+)'/g,
  // classifieds' theme busts its stylesheet cache with the current time (YmdHis)
  /style\.css\?v=(\d{14})/g,
];

// Gitea defines the file icons a listing uses as hidden SVGs, in Go map order; sort them
const sortGiteaIconDefinitions = (page: string) =>
  page.replace(
    /<div class="svg-icon-container">((?:<svg id="svg-mfi-[^"]+"[\s\S]*?<\/svg>)+)<\/div>/g,
    (_, svgs: string) =>
      `<div class="svg-icon-container">${svgs
        .match(/<svg[\s\S]*?<\/svg>/g)
        ?.sort()
        .join("")}</div>`,
  );

function normalize(pages: string[]): string[] {
  return maskRandomTokens(pages.map(sortGiteaIconDefinitions));
}

function maskRandomTokens(pages: string[]): string[] {
  const tokens = new Set<string>();
  for (const page of pages) {
    for (const pattern of RANDOM_TOKENS) {
      for (const match of page.matchAll(pattern)) {
        tokens.add(match[1]);
      }
    }
  }
  // Longest first, so a token that contains another is masked whole
  const sorted = [...tokens].sort((a, b) => b.length - a.length);
  return pages.map((page) =>
    sorted.reduce((text, token) => text.replaceAll(token, "<random>"), page),
  );
}

// Where the two copies part, with some context, so a failure names the changing value
function firstDifference(a: string, b: string): string | undefined {
  if (a === b) {
    return undefined;
  }
  let i = 0;
  while (a[i] === b[i]) {
    i++;
  }
  return `at ${i}:\n  ${a.slice(Math.max(0, i - 80), i + 80)}\n  ${b.slice(Math.max(0, i - 80), i + 80)}`;
}

const zooSitesPages = getAllSites()
  .filter((site: { service?: string }) => site.service === "zoo-sites")
  .map((site: { domain: string }) => `https://${site.domain}/`);

const PAGES = [
  "https://home.zoo/",
  "https://example.zoo/",
  "https://performance.zoo/",
  "https://auth.zoo/",
  "https://auth.zoo/register",
  "https://auth.zoo/explore",
  "https://misc.zoo/",
  "https://docs.gitea.zoo/",
  "https://gitea.zoo/",
  "https://gitea.zoo/explore/repos",
  "https://gitea.zoo/alice/hello-zoo",
  "https://wiki.zoo/",
  "https://paste.zoo/",
  "https://excalidraw.zoo/",
  "https://focalboard.zoo/",
  "https://mattermost.zoo/",
  "https://miniflux.zoo/",
  "https://snappymail.zoo/",
  "https://analytics.zoo/",
  "https://northwind.zoo/",
  "https://postmill.zoo/",
  "https://classifieds.zoo/",
  "https://onestopshop.zoo/",
  ...zooSitesPages,
].filter(isUrlAvailable);

describe("Pages are the same on every fetch", () => {
  // The first fetch warms up an on-demand app and any caches; the next two are compared
  test.each(PAGES)("%s", { timeout: COLD_START_TIMEOUT }, async (url) => {
    const warmUp = await fetchWithProxy(url, { timeout: COLD_START_TIMEOUT - 10000 });
    expect(warmUp.httpCode, `${url}: ${warmUp.error ?? ""}`).toBe(200);

    const first = await fetchWithProxy(url, { timeout: 5000 });
    const second = await fetchWithProxy(url, { timeout: 5000 });
    expect([first.httpCode, second.httpCode]).toEqual([200, 200]);

    const [a, b] = normalize([first.body, second.body]);
    expect(firstDifference(a, b)).toBeUndefined();
  });
});
