# The Zoo

The Zoo is a simulated web environment. It's meant to be complex enough for true end-to-end testing (like the live web), while being reproducible (unlike the live web).

Web services are hosted on the `.zoo` domain accessible through a forward proxy.

## Prerequisites

[Docker](https://docs.docker.com/engine/install/), [Docker Compose](https://docs.docker.com/compose/install/), [NodeJS](https://nodejs.org/en/download/) are required to run the Zoo. Make sure you have the latest version of each installed on the host machine.

## Installation

```bash
npm install
npm start
```

For install/start issues, see [here](#troubleshooting).

### Core Services

- **Squid Proxy** (Port 3128) - HTTP proxy for host browser access
- **CoreDNS** - DNS server for all containers in the environment, resolves `.zoo` domains (domains are specified in docker-compose or based on file path).
- **Caddy** - Reverse proxy and static file server. Also handles SSL, with private keys committed for reproducibility.
- **PostgreSQL** - Resets database state [on container restart](core/postgres/Dockerfile)
- **MySQL** - Resets database state [on container restart](core/mysql/Dockerfile)
- **Redis** - Key-value store
- **Stalwart** - Mail server ([GitHub](https://github.com/stalwartlabs/mail-server))
- **Hydra** - OAuth2/OpenID Connect server ([Ory Hydra](https://github.com/ory/hydra))

### Sites

- **Apps** - Located in `sites/apps/`, each directory is a `.zoo` domain
- **Static Sites** - Located in `sites/static/`, served directly by Caddy

## Setup instructions for manual browsing

In the main repo you can use `npm run browse` to open a configured playwright instance (make sure you've installed playwright by running `npx playwright install-deps && npx playwright install` first).

However, it's better to just customize a normal Firefox profile to manually browse.

1. Create a brand new profile (about:profiles, or in [Nightly](https://www.mozilla.org/en-US/firefox/channel/desktop/) use the profile selector)
2. Type about:support in the address bar and show the profile folder
3. Copy/paste [`docs/firefox-profile/user.js`](./docs/firefox-profile/user.js) into the profile folder. This has conveniences like recognizing `.zoo` as a valid domain suffix.
4. about:preferences#privacy -> Certificates -> View Certificates -> Import. Select [`core/caddy/root.crt`](./core/caddy/root.crt) from the project. Check "Trust this CA to identify websites".
5. Restart Firefox (about:profiles -> Restart Normally)
6. Configure the Zoo proxy: about:preferences#general -> Network Settings -> Settings... -> Configure Proxy Access to the Internet -> Manual Proxy Configuration -> HTTP (HTTPS) Proxy "localhost" -> Port(s) "3128".

## Auth.zoo Users

Test user credentials are available in [`scripts/seed-data/personas.ts`](./scripts/seed-data/personas.ts)

## Available Sites

### Applications Gallery

| Screenshot                                                                          | Site                                       | Description                                               |
| ----------------------------------------------------------------------------------- | ------------------------------------------ | --------------------------------------------------------- |
| <img src="docs/screenshots/analytics-zoo.avif" width="200" alt="analytics.zoo">     | [analytics.zoo](https://analytics.zoo)     | Web analytics platform powered by Matomo                  |
| <img src="docs/screenshots/auth-zoo.avif" width="200" alt="auth.zoo">               | [auth.zoo](https://auth.zoo)               | auth.zoo                                                  |
| <img src="docs/screenshots/classifieds-zoo.avif" width="200" alt="classifieds.zoo"> | [classifieds.zoo](https://classifieds.zoo) | Classified ads marketplace from VisualWebArena            |
| <img src="docs/screenshots/example-zoo.avif" width="200" alt="example.zoo">         | [example.zoo](https://example.zoo)         | example.zoo                                               |
| <img src="docs/screenshots/excalidraw-zoo.avif" width="200" alt="excalidraw.zoo">   | [excalidraw.zoo](https://excalidraw.zoo)   | Virtual whiteboard for sketching diagrams                 |
| <img src="docs/screenshots/focalboard-zoo.avif" width="200" alt="focalboard.zoo">   | [focalboard.zoo](https://focalboard.zoo)   | Open source project management and kanban boards          |
| <img src="docs/screenshots/gitea-zoo.avif" width="200" alt="gitea.zoo">             | [gitea.zoo](https://gitea.zoo)             | Self-hosted Git service with web interface                |
| <img src="docs/screenshots/home-zoo.avif" width="200" alt="home.zoo">               | [home.zoo](https://home.zoo)               | home.zoo                                                  |
| <img src="docs/screenshots/miniflux-zoo.avif" width="200" alt="miniflux.zoo">       | [miniflux.zoo](https://miniflux.zoo)       | Minimalist feed reader with RSS/Atom support              |
| <img src="docs/screenshots/misc-zoo.avif" width="200" alt="misc.zoo">               | [misc.zoo](https://misc.zoo)               | Miscellaneous utilities and test endpoints                |
| <img src="docs/screenshots/northwind-zoo.avif" width="200" alt="northwind.zoo">     | [northwind.zoo](https://northwind.zoo)     | Northwind sample database with phpMyAdmin interface       |
| <img src="docs/screenshots/onestopshop-zoo.avif" width="200" alt="onestopshop.zoo"> | [onestopshop.zoo](https://onestopshop.zoo) | E-commerce shopping site from VisualWebArena              |
| <img src="docs/screenshots/paste-zoo.avif" width="200" alt="paste.zoo">             | [paste.zoo](https://paste.zoo)             | Self-hosted pastebin                                      |
| <img src="docs/screenshots/performance-zoo.avif" width="200" alt="performance.zoo"> | [performance.zoo](https://performance.zoo) | Performance testing and monitoring tools                  |
| <img src="docs/screenshots/postmill-zoo.avif" width="200" alt="postmill.zoo">       | [postmill.zoo](https://postmill.zoo)       | Reddit-like forum and link aggregator from VisualWebArena |
| <img src="docs/screenshots/snappymail-zoo.avif" width="200" alt="snappymail.zoo">   | [snappymail.zoo](https://snappymail.zoo)   | Modern webmail client with clean interface                |
| <img src="docs/screenshots/wiki-zoo.avif" width="200" alt="wiki.zoo">               | [wiki.zoo](https://wiki.zoo)               | Offline Wikipedia reader and knowledge base               |

## Troubleshooting

Upon setting up the Zoo on different host machines, two issues where identified that can be fixed by extending the Docker daemon configuration. First, create the `/etc/docker/daemon.json` file (if it does not already exist).

| **Error**                                                                                                                                  | **Fix**                                                                                                                            |
| ------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `cache export is not supported for the docker driver. switch to a different driver, or turn on the containerd image store, and try again.` | You can enable the containerd image store by adding the `"containerd-snapshotter": true` attribute to `daemon.json`                |
| `wget: unable to resolve host address ‘dl-cdn.alpinelinux.org’`                                                                            | You can configure Docker to use an alternative DNS server by adding the `"dns": ["8.8.8.8", "1.1.1.1"]` attribute to `daemon.json` |

If you've run into both issues and you've attempted to resolve both, your `docker.json` should look like this:

```json
{
  "features": {
    "containerd-snapshotter": true
  },
  "dns": ["8.8.8.8", "1.1.1.1"]
}
```

Finally, restart Docker:

```bash
sudo systemctl restart docker
```
