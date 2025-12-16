# Analytics

Matomo at https://analytics.zoo — login: `analytics_user` / `analytics_pw`

## What's Tracked

Page views, clicks, forms, searches, errors, performance, scroll depth, downloads.

Caddy injects `<script src="https://performance.zoo/shared.js">` into all HTML pages.

## Adding a Site

1. Create site in Matomo: Administration → Measurables → Add (choose "Intranet Website")
2. Add site ID to `sites/static/performance.zoo/dist/shared.js`:
   ```javascript
   const SITE_IDS = {
     "mynewsite.zoo": 16,
   };
   ```
3. Restart: `docker compose restart performance-zoo caddy`
4. Capture state: `./scripts/seed-data/capture-analytics-state.sh`

## Data Persistence

- **Preserved**: `core/mysql/sql/analytics_seed.sql`, `sites/apps/analytics.zoo/data-golden/config/`
- **Ephemeral**: Visit data resets on each `npm start`
