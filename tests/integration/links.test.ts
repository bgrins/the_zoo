import { beforeAll, describe, expect, test } from "vitest";
import { getAllSites } from "../../scripts/sites-registry";
import { COLD_START_TIMEOUT, EXTRA_EXTENDED_TEST_TIMEOUT } from "../constants";
import { isUrlAvailable } from "../utils/available";
import { BrowserSession } from "../utils/browser-session";
import { warmUp } from "../utils/on-demand";

const sites: { domain: string; service?: string }[] = getAllSites();

const KNOWN_HOSTS = new Set(sites.map((site) => site.domain));

// The zoo's own pages, which link only within it (the proxy refuses anything else); the
// apps' pages may link out
const OWN_HOSTS = new Set(["home.zoo", "auth.zoo", "example.zoo", "performance.zoo", "misc.zoo"]);

const ZOO_SITES_PAGES = sites
  .filter((site) => site.service === "zoo-sites")
  .map((site) => `https://${site.domain}/`);

// Pages whose links are checked, including the seeded content that needs no login
const START_PAGES = [
  "https://home.zoo/",
  "https://auth.zoo/",
  "https://auth.zoo/register",
  "https://auth.zoo/explore",
  "https://example.zoo/",
  "https://performance.zoo/",
  "https://misc.zoo/",
  "https://docs.gitea.zoo/",
  "https://gitea.zoo/",
  "https://gitea.zoo/explore/repos",
  "https://gitea.zoo/explore/users",
  "https://gitea.zoo/explore/organizations",
  "https://postmill.zoo/",
  "https://classifieds.zoo/",
  "https://onestopshop.zoo/",
  ...ZOO_SITES_PAGES,
].filter(isUrlAvailable);

// Links from the start pages to these are checked as well: Gitea's seeded users, orgs and
// repos (profiles and READMEs)
const FOLLOW: Record<string, (path: string) => boolean> = {
  "gitea.zoo": (path) =>
    /^\/[\w.-]+(\/[\w.-]+)?$/.test(path) &&
    !/^\/(api|assets|avatars|explore|repo|user)(\/|$)/.test(path),
};

const decodeEntities = (value: string) =>
  value
    .replace(/&amp;/g, "&")
    .replace(/&#x2F;/gi, "/")
    .replace(/&#47;/g, "/");

function linksIn(html: string, pageUrl: string): URL[] {
  const links: URL[] = [];
  for (const match of html.matchAll(/\b(?:href|src|action)\s*=\s*(?:"([^"]*)"|'([^']*)')/gi)) {
    try {
      const url = new URL(decodeEntities(match[1] ?? match[2]), pageUrl);
      if (url.protocol === "http:" || url.protocol === "https:") {
        links.push(url);
      }
    } catch {
      // Not a URL (template placeholders and the like)
    }
  }
  return links;
}

async function fetchPage(url: string): Promise<{ url: string; html: string }> {
  const page = await new BrowserSession().request(url, { timeout: 15000 });
  expect(page.httpCode, `${url} → ${page.finalUrl}`).toBe(200);
  return { url: page.finalUrl, html: page.body };
}

async function inBatches<T, R>(items: T[], size: number, fn: (item: T) => Promise<R>) {
  const results: R[] = [];
  for (let i = 0; i < items.length; i += size) {
    results.push(...(await Promise.all(items.slice(i, i + size).map(fn))));
  }
  return results;
}

describe("Links between zoo sites", () => {
  beforeAll(async () => {
    await Promise.all(
      ["https://gitea.zoo/", "https://voltro.zoo/", "https://docs.gitea.zoo/", "https://misc.zoo/"]
        .concat(["https://postmill.zoo/", "https://classifieds.zoo/", "https://onestopshop.zoo/"])
        .filter(isUrlAvailable)
        .map(warmUp),
    );
  }, COLD_START_TIMEOUT);

  test(
    "point at zoo hosts that exist, over https",
    async () => {
      const pages = await inBatches(START_PAGES, 8, fetchPage);
      const followed = [
        ...new Set(
          pages.flatMap((page) =>
            linksIn(page.html, page.url)
              .filter((link) => FOLLOW[link.hostname]?.(link.pathname))
              .map((link) => link.origin + link.pathname),
          ),
        ),
      ].filter((url) => !START_PAGES.includes(url));
      expect(followed).toEqual(
        expect.arrayContaining(["https://gitea.zoo/alice", "https://gitea.zoo/alice/hello-zoo"]),
      );
      pages.push(...(await inBatches(followed, 8, fetchPage)));

      const problems = new Set<string>();
      for (const page of pages) {
        for (const link of linksIn(page.html, page.url)) {
          if (!link.hostname.endsWith(".zoo")) {
            if (OWN_HOSTS.has(new URL(page.url).hostname) && !KNOWN_HOSTS.has(link.hostname)) {
              problems.add(`${page.url}: ${link.href} (outside the zoo)`);
            }
            continue;
          }
          if (!KNOWN_HOSTS.has(link.hostname)) {
            problems.add(`${page.url}: ${link.href} (no such site)`);
          } else if (link.protocol === "http:") {
            problems.add(`${page.url}: ${link.href} (http)`);
          }
        }
      }
      expect([...problems].sort()).toEqual([]);
    },
    EXTRA_EXTENDED_TEST_TIMEOUT,
  );
});
