# auth.zoo

The zoo's single sign-on: a login/consent app for [Ory Hydra](https://github.com/ory/hydra), which serves OAuth2/OIDC under `https://auth.zoo` (`/.well-known/openid-configuration`, `/oauth2/*`, `/userinfo`). Users live in Postgres (`auth_db`) and are the personas in [`scripts/seed-data/personas.ts`](../../../scripts/seed-data/personas.ts); their UUIDs (`personaId`) are the OAuth subjects the other apps link to. Hydra's clients are in `core/hydra`.

## Development

The source is bind-mounted; `docker compose restart auth-zoo` picks up edits. `npm run typecheck:auth` typechecks it (after `npm ci --prefix sites/apps/auth.zoo`).

The dependencies are the image's, in `/node_modules`; a tmpfs hides any installed in the checkout. After a dependency change: `docker compose build auth-zoo && docker compose up -d auth-zoo`.

Environment: `PORT` (3000), `SMTP_HOST`, `SMTP_PORT`, `SMTP_FROM`.
