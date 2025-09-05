# The Zoo

The Zoo is a simulated web environment. It's meant to be complex enough for true end-to-end testing (like the live web), while being reproducible testing (unlike the live web).

Web services are hosted on the `.zoo` domain accessible through a forward proxy.

## Prerequisites

[Docker](https://docs.docker.com/engine/install/), [Docker Compose](https://docs.docker.com/compose/install/) and [NodeJS](https://nodejs.org/en/download/) are required to run the Zoo. Make sure you have the latest version of each installed on the host machine. 

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
- **Stalwart** - Mail server ([GitHub](https://github.com/stalwartlabs/mail-server))
- **Hydra** - OAuth2/OpenID Connect server ([Ory Hydra](https://github.com/ory/hydra))
- **Meilisearch** - Search engine API ([GitHub](https://github.com/meilisearch/meilisearch))

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

## Available Sites

### Applications Gallery

| Screenshot                                                                              | Site                                               | Description                                                                                                 |
| --------------------------------------------------------------------------------------- | -------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| <img src="docs/screenshots/auth-zoo.avif" width="200" alt="auth.zoo">                   | **[auth.zoo](https://auth.zoo)**                   | OAuth2/OpenID Connect authentication service                                                                |
| <img src="docs/screenshots/classifieds-zoo.avif" width="200" alt="classifieds.zoo">     | **[classifieds.zoo](https://classifieds.zoo)**     | Visual Web Arena classifiends app ([optimized](https://briangrinstead.com/blog/shrinking-vwa-classifieds/)) |
| <img src="docs/screenshots/excalidraw-zoo.avif" width="200" alt="excalidraw.zoo">       | **[excalidraw.zoo](https://excalidraw.zoo)**       | Virtual whiteboard ([Excalidraw](https://github.com/excalidraw/excalidraw))                                 |
| <img src="docs/screenshots/focalboard-zoo.avif" width="200" alt="focalboard.zoo">       | **[focalboard.zoo](https://focalboard.zoo)**       | Project management and kanban boards ([Focalboard](https://github.com/mattermost/focalboard))               |
| <img src="docs/screenshots/gitea-zoo.avif" width="200" alt="gitea.zoo">                 | **[gitea.zoo](https://gitea.zoo)**                 | Self-hosted Git service ([Gitea](https://github.com/go-gitea/gitea))                                        |
| <img src="docs/screenshots/lorem-rss-zoo.avif" width="200" alt="lorem-rss.zoo">         | **[lorem-rss.zoo](https://lorem-rss.zoo)**         | Lorem ipsum RSS feed generator for testing                                                                  |
| <img src="docs/screenshots/miniflux-zoo.avif" width="200" alt="miniflux.zoo">           | **[miniflux.zoo](https://miniflux.zoo)**           | Minimalist feed reader ([Miniflux](https://github.com/miniflux/v2))                                         |
| <img src="docs/screenshots/northwind-zoo.avif" width="200" alt="northwind.zoo">         | **[northwind.zoo](https://northwind.zoo)**         | Northwind sample database with phpMyAdmin interface                                                         |
| <img src="docs/screenshots/oauth-example-zoo.avif" width="200" alt="oauth-example.zoo"> | **[oauth-example.zoo](https://oauth-example.zoo)** | OAuth2/OIDC integration example application                                                                 |
| <img src="docs/screenshots/performance-zoo.avif" width="200" alt="performance.zoo">     | **[performance.zoo](https://performance.zoo)**     | Performance testing and monitoring tools                                                                    |
| <img src="docs/screenshots/planka-zoo.avif" width="200" alt="planka.zoo">               | **[planka.zoo](https://planka.zoo)**               | Trello-inspired project management ([Planka](https://github.com/plankanban/planka))                         |
| <img src="docs/screenshots/search-zoo.avif" width="200" alt="search.zoo">               | **[search.zoo](https://search.zoo)**               | Full-text search interface for the Zoo                                                                      |
| <img src="docs/screenshots/snappymail-zoo.avif" width="200" alt="snappymail.zoo">       | **[snappymail.zoo](https://snappymail.zoo)**       | Modern webmail client ([SnappyMail](https://github.com/the-djmaze/snappymail))                              |
| <img src="docs/screenshots/utils-zoo.avif" width="200" alt="utils.zoo">                 | **[utils.zoo](https://utils.zoo)**                 | Utility tools and development helpers                                                                       |
| <img src="docs/screenshots/wiki-zoo.avif" width="200" alt="wiki.zoo">                   | **[wiki.zoo](https://wiki.zoo)**                   | Offline Wikipedia reader ([Kiwix](https://github.com/kiwix/kiwix-tools))                                    |
