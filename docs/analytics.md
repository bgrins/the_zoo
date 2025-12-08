# Analytics Setup

Matomo analytics is pre-configured for tracking .zoo sites with comprehensive agent behavior monitoring.

## Quick Start

```bash
npm start
```

Visit `https://analytics.zoo` and login:

- Username: `analytics_user`
- Password: `analytics_pw`

### What's Tracked Automatically

- **Page views** with cross-domain tracking
- **All clicks** (buttons, links, elements)
- **Form interactions** (focus, blur, submit)
- **Searches** (queries and results)
- **Errors** (JavaScript, AJAX, promises)
- **Performance** (load times, AJAX timing)
- **Engagement** (scroll depth, time on page, visibility)
- **Downloads & outlinks**

## Adding a New Site

### Quick Method

1. **Create site in Matomo UI**: Administration → Measurables → Add (choose "Intranet Website")
2. **Note the Site ID** (e.g., `16`)
3. **Add to `sites/apps/performance.zoo/public/shared.js`**:

```javascript
const SITE_IDS = {
  // ... existing sites ...
  "mynewsite.zoo": 16,
};
```

4. **Restart**: `docker compose restart performance-zoo caddy`
5. **Test**: Visit `http://mynewsite.zoo` and check console for tracking initialization
6. **Capture golden state**: `./scripts/seed-data/capture-analytics-state.sh`
7. **Commit**: `git add core/mysql/sql/analytics_seed.sql sites/apps/analytics.zoo/data-golden/ sites/apps/performance.zoo/public/shared.js`

## Architecture

```
Caddy Proxy
    ↓ (injects shared.js before </body>)
performance.zoo
    ↓ (serves shared.js with tracking code)
analytics.zoo
    ↓ (stores all tracking data)
MySQL (analytics_db)
```

### Data Persistence

- **Golden state** (preserved):
  - `core/mysql/sql/analytics_seed.sql` - Database schema + site configurations
  - `sites/apps/analytics.zoo/data-golden/config/` - Matomo configuration files
- **Runtime data** (ephemeral, gitignored):
  - `data/matomo/` - Matomo files
  - Analytics visits/events reset on each `npm start`
- **Tracking injection**:
  - Caddy automatically injects `<script src="https://performance.zoo/shared.js">` into all HTML pages
  - See `core/caddy/Caddyfile` snippet `(performance_zoo)`

**Note**: Analytics visit/pageview data is ephemeral and resets on each `npm start`. Site configurations and admin user are preserved via golden state. For persistent data collection across restarts, use an external harness to dump and restore analytics data.
