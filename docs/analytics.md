# Analytics

Matomo at https://analytics.zoo — login: `analytics_user` / `analytics_pw`, API token `548352a992deec98a8a2af37460fdf71`

## What's Tracked

Page views, clicks, forms, searches, errors, the page's `fetch()` calls, performance, scroll depth, downloads.

Caddy injects `<script src="https://performance.zoo/shared.js">` into all HTML pages. Every zoo site with pages has a Matomo site; `SITE_IDS` in shared.js maps domains to them.

## Tagging a Run

Every Matomo site has four visit-scope custom dimensions, each read from a cookie:

| ID | Name           | Cookie           | Without the cookie                                                                       |
| -- | -------------- | ---------------- | ---------------------------------------------------------------------------------------- |
| 1  | Agent Type     | `zoo_agent_type` | The browser, plus `(automated)` when `navigator.webdriver` is set: `Firefox (automated)` |
| 2  | Run ID         | `zoo_run_id`     | None                                                                                     |
| 3  | Task Type      | `zoo_task_type`  | `general`                                                                                |
| 4  | Attempt Number | `zoo_attempt`    | `1`                                                                                      |

`window.__zooTracking.setAgentContext({ agentType, runId, taskType, attemptNumber })` sets the cookies on the current site.

A harness tags a run by setting `zoo_run_id` (and the others it needs) on each domain it visits before loading pages. Browsers refuse a cookie for all of `.zoo`, which is a public suffix, so set one per domain:

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

Golden state: `core/mysql/sql/analytics_seed.sql` and `sites/apps/analytics.zoo/data-golden/config/`; visits reset with mysql.
