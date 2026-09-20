# Analytics

Matomo at https://analytics.zoo — login: `analytics_user` / `analytics_pw`, API token `548352a992deec98a8a2af37460fdf71`

## What's Tracked

Page views, clicks, forms, searches, errors, the page's `fetch()` calls, performance, scroll depth, downloads.

Caddy injects `<script src="https://performance.zoo/shared.js">` into all HTML pages. Every zoo site with pages has a Matomo site; `SITE_IDS` in shared.js maps domains to them.

## Tagging a Run

Every Matomo site has four visit-scope custom dimensions:

| ID | Name           | Value                                                              |
| -- | -------------- | ------------------------------------------------------------------ |
| 1  | Agent Type     | Guessed from the user agent                                        |
| 2  | Run ID         | The `zoo_run_id` cookie                                            |
| 3  | Task Type      | `general`, or `window.__zooTracking.setAgentContext({ taskType })` |
| 4  | Attempt Number | `1`, or `setAgentContext({ attemptNumber })`                       |

A harness tags a run by setting `zoo_run_id` on each domain it visits before loading pages. Browsers refuse a cookie for all of `.zoo`, which is a public suffix, so set one per domain:

```ts
const domains = yaml
  .parse(fs.readFileSync("core/SITES.yaml", "utf8"))
  .sites.map((s) => s.domain);
await context.addCookies(
  domains.map((domain) => ({
    name: "zoo_run_id",
    value: runId,
    domain,
    path: "/",
  })),
);
```

Afterwards, export the run's visits and their actions as JSON:

```bash
npx tsx scripts/analytics-export-run.ts <run-id> [date]   # date: a Matomo range, default last2
```

## Adding a Site

1. Create the site in Matomo (API, or Administration → Measurables → Add "Intranet Website") with `https://` and `http://` URLs and the four custom dimensions above, in that order
2. `npm run generate-config` adds it to `SITE_IDS` in shared.js
3. `npm run golden:capture -- analytics`, then run the rebuild steps it prints

## Data Persistence

- **Preserved**: `core/mysql/sql/analytics_seed.sql`, `sites/apps/analytics.zoo/data-golden/config/`
- **Ephemeral**: Visit data resets on each `npm start`
