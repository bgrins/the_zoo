# Analytics Setup

Matomo analytics is pre-configured for tracking .zoo sites.

## Quick Start

```bash
npm start
```

Visit `https://analytics.zoo` and login:

- Username: `analytics_user`
- Password: `analytics_pw`

## Adding a New Site

1. **Create site in Matomo UI**: Administration → Measurables → Add (choose "Intranet Website")
2. **Note the Site ID** (e.g., `3`)
3. **Add to `sites/apps/performance.zoo/public/shared.js`**:

```javascript
} else if (currentDomain === 'example.zoo') {
  var _paq = window._paq = window._paq || [];
  _paq.push(['trackPageView']);
  _paq.push(['enableLinkTracking']);
  (function() {
    var u="//analytics.zoo/";
    _paq.push(['setTrackerUrl', u+'matomo.php']);
    _paq.push(['setSiteId', '3']); // Your Site ID
    var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
    g.async=true; g.src=u+'matomo.js'; s.parentNode.insertBefore(g,s);
  })();
}
```

4. **Restart**: `docker compose restart performance-zoo caddy`
5. **Capture golden state**: `./scripts/seed-data/capture-analytics-state.sh`
6. **Commit**: `git add core/mysql-analytics/ sites/apps/analytics.zoo/data-golden/ sites/apps/performance.zoo/public/shared.js`

## Architecture

- **Golden state** (committed): `core/mysql-analytics/seed/analytics.sql`, `sites/apps/analytics.zoo/data-golden/`
- **Runtime data** (gitignored): `data/mysql-analytics/`, `data/matomo/`
- **Tracking**: Caddy injects `shared.js` into all .zoo pages

## Troubleshooting

**No tracking logs in console?** Hard refresh or clear cache

**SSL certificate error?** Accept certs for `performance.zoo` and `analytics.zoo`

**Setup wizard appears?** Run `./scripts/seed-data/capture-analytics-state.sh` and rebuild mysql-analytics
