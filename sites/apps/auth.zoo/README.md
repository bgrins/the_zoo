# auth.zoo

The zoo's single sign-on: a login/consent app for [Ory Hydra](https://github.com/ory/hydra), which serves OAuth2/OIDC under `https://auth.zoo` (`/.well-known/openid-configuration`, `/oauth2/*`, `/userinfo`). Users live in Postgres (`auth_db`) and are the personas in [`scripts/seed-data/personas.ts`](../../../scripts/seed-data/personas.ts); their UUIDs (`personaId`) are the OAuth subjects the other apps link to. Hydra's clients are in `core/hydra`.

## Development

The source is bind-mounted; `docker compose restart auth-zoo` picks up edits. `npm run typecheck:auth` typechecks it (after `npm ci --prefix sites/apps/auth.zoo`).

`node_modules` lives in the `auth_zoo_modules` volume, which Docker fills from the image only when it creates the volume. After a dependency change:

```bash
docker compose build auth-zoo && docker compose rm -sf auth-zoo
docker volume rm <project>_auth_zoo_modules && docker compose up -d auth-zoo
```

Environment: `PORT` (3000), `SMTP_HOST`, `SMTP_PORT`, `SMTP_FROM`.
