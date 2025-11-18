# Analytics Setup

Matomo analytics is pre-configured for tracking .zoo sites with comprehensive agent behavior monitoring.

## Quick Start

```bash
npm start
```

Visit `https://analytics.zoo` and login:

- Username: `analytics_user`
- Password: `analytics_pw`

## Comprehensive Tracking

The Zoo implements extensive analytics tracking for LLM agent research. See [Analytics Tracking Guide](./analytics-tracking-guide.md) for full details on:

- 20+ tracking categories (navigation, interactions, errors, performance, etc.)
- Custom agent context via public API
- Public API for custom event tracking
- Site search tracking

### What's Tracked Automatically

- **Page views** with cross-domain tracking
- **All clicks** (buttons, links, elements)
- **Form interactions** (focus, blur, submit)
- **Searches** (queries and results)
- **Errors** (JavaScript, AJAX, promises)
- **Performance** (load times, AJAX timing)
- **Engagement** (scroll depth, time on page, visibility)
- **Downloads & outlinks**

### Agent Context Tracking

Set agent-specific metadata for tracking:

```javascript
window.__zooTracking.setAgentContext({
  agentType: "Claude-Sonnet-4",
  taskType: "email-composition",
  attemptNumber: 2,
});
```

**Note**: Custom dimensions must be created in Matomo UI first (Administration → Custom Dimensions) to store this data.

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

### Full Setup

See [Analytics Tracking Guide - Setting Up New Sites](./analytics-tracking-guide.md#setting-up-new-sites-in-matomo) for complete setup.

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

## Using the Tracking API

From any .zoo page with tracking enabled:

```javascript
// Track custom events
window.__zooTracking.trackEvent("Email", "Send", "success", 1);

// Track goal completion (requires goal creation in Matomo UI first)
window.__zooTracking.trackGoal(1); // Goal 1: Task completed

// Set agent context (requires custom dimensions in Matomo UI first)
window.__zooTracking.setAgentContext({
  agentType: "Claude-Sonnet-4",
  taskType: "send-email",
  attemptNumber: 2,
});

// Track search with results
window.__zooTracking.trackSearch("authentication", "documentation", 42);
```

See [Analytics Tracking Guide](./analytics-tracking-guide.md) for complete API documentation.
