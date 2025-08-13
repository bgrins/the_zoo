# The Zoo

The Zoo is a simulated web environment. It's meant to be complex enough for true end-to-end testing (like the live web), while being reproducible testing (unlike the live web).

Web services are hosted on the `.zoo` domain accessible through a forward proxy.

## Installation

```bash
npm install
npm start
```

### Core Services

- **Squid Proxy** (Port 3128) - HTTP proxy for host browser access
- **CoreDNS** - DNS server for all containers in the environment, resolves `.zoo` domains (domains are specified in docker-compose or based on file path).
- **Caddy** - Reverse proxy and static file server. Also handles SSL, with private keys committed for reproducibility.
- **PostgreSQL** - Resets database state [on container restart](core/postgres/Dockerfile)
- **MySQL** - Resets database state [on container restart](core/mysql/Dockerfile)
- **Redis** - Key-value store
- **Stalwart** - Mail server
- **Hydra** - OAuth2/OpenID Connect server, with a frontend at [https://auth.zoo]

### Sites

- **Apps** - Located in `sites/apps/`, each directory is a `.zoo` domain
- **Static Sites** - Located in `sites/static/`, served directly by Caddy

## Setup instructions for manual browsing

In the main repo you can use `npm run browse` to open a configured playwright instance, but it's better to just customize a normal Firefox profile to manually browse.

1. Create a brand new profile (about:profiles, or in [Nightly](https://www.mozilla.org/en-US/firefox/channel/desktop/) use the profile selector)
2. Type about:support in the address bar and show the profile folder
3. Copy/paste [`docs/firefox-profile/user.js`](./docs/firefox-profile/user.js) into the profiler folder. This has conveniences like recoginizing `.zoo` as a valid domain suffix.
4. about:preferences#privacy -> Certificates -> View Certificates -> Import. Select [`core/caddy/root.crt`](./data/caddy/data/pki/authorities/local/root.crt) from the project. Check "Trust this CA to identify websites".
5. about:preferences#search
   Search Shortcuts -> Uncheck everything then do Add (Name = Zoo Search, Url = https://search.zoo/?q=%s)
   Default Search Engine -> Zoo Search
6. Restart Firefox (about:profiles -> Restart Normally)

## Auth.zoo Users

Test user credentials are available in [`scripts/seed-data/personas.ts`](./scripts/seed-data/personas.ts)
