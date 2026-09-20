# Auth.zoo - Identity Management for The Zoo

Auth.zoo is the central identity management system for The Zoo, providing OAuth2/OIDC authentication powered by ORY Hydra.

## Architecture

- **ORY Hydra**: Handles OAuth2/OIDC protocol (headless)
- **Auth.zoo**: Provides login/consent UI and user management
- **PostgreSQL**: Stores user accounts and Hydra's OAuth2 data

## Features

- ✅ OAuth2/OpenID Connect authentication
- ✅ User registration and profile management
- ✅ Database-backed user accounts with bcrypt password hashing
- ✅ Automatic seed data loading for test users
- ✅ Connected applications management
- ✅ Password change functionality
- ✅ Session management with logout

## Database Schema

The system uses PostgreSQL with automatic migrations:

```sql
users (
  id UUID PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

## Test Users

Test users come from the personas in [`scripts/seed-data/personas.ts`](../../../scripts/seed-data/personas.ts), for example **admin** / admin123, **alice** / alice123, **bob** / bob123. `npm run seed` creates them through `POST /api/users` with fixed IDs (`personaId` in that file), and the result is captured in the Postgres golden state so a fresh start already has them.

## API Endpoints

### Public Endpoints

- `GET /` - Homepage
- `GET /register` - Registration page
- `POST /register` - Create new account
- `GET /login` - OAuth2 login flow
- `POST /login` - Process login
- `GET /consent` - OAuth2 consent flow
- `POST /consent` - Process consent
- `GET /error` - OAuth2 error page (Hydra's `urls.error`)
- `GET /logout` - OAuth2 logout flow (Hydra's `urls.logout`)

### Authenticated Endpoints

- `GET /dashboard` - User dashboard
- `GET /profile` - Edit profile page
- `POST /profile` - Update profile
- `POST /change-password` - Change password
- `POST /logout` - Logout (also ends the Hydra login session)
- `POST /revoke-app` - Revoke app access

### OAuth2/OIDC Endpoints (proxied from Hydra)

- `GET /.well-known/openid-configuration` - OIDC discovery
- `GET /.well-known/jwks.json` - JSON Web Key Set
- `GET /oauth2/auth` - Authorization endpoint
- `POST /oauth2/token` - Token endpoint
- `GET /userinfo` - UserInfo endpoint

## Development

### File Structure

```
auth.zoo/
├── server.ts          # Express server, Hydra proxying, startup migrations
├── db.ts              # PostgreSQL connection pool
├── migrate.ts         # Migration runner
├── userService.ts     # User CRUD operations
├── hydraClient.ts     # Hydra admin API client
├── emailService.ts    # Notification emails via Stalwart SMTP
├── routes/            # auth, oauth (login/consent/logout/error), dashboard, api
├── utils/             # Page rendering helpers
└── migrations/        # SQL migrations
```

The source is bind-mounted into the container. After editing, run `docker compose restart auth-zoo`.

Dependencies are different: they live in the `auth_zoo_modules` named volume, mounted over `/app/node_modules`. Docker fills that volume from the image only when it creates the volume, so after a `package.json` or `package-lock.json` change the stale `node_modules` hide the rebuilt image's. Rebuild the image, then recreate the volume:

```bash
docker compose build auth-zoo
docker compose rm -sf auth-zoo
docker volume rm <project>_auth_zoo_modules
docker compose up -d auth-zoo
```

`<project>` is the compose project name: the checkout's directory name (e.g. `the_zoo`) unless `COMPOSE_PROJECT_NAME` is set. `npm run reset` also recreates the volume, along with every other volume, but it does not rebuild the image.

### Environment Variables

- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (default: development)
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_FROM` - Outgoing mail settings

### Database Connection

- Host: `postgres.zoo`
- Database: `auth_db`
- User: `auth_user`
- Password: `auth_pw`

## Testing OAuth2 Flow

1. Visit any OAuth2-enabled app (e.g., http://misc.zoo)
2. Click "Login with OAuth2"
3. Enter credentials for any test user
4. Authorize the application
5. You'll be redirected back with an access token

## Resetting the System

auth.zoo's data lives in Postgres, which resets to its golden state when the container restarts:

```bash
docker compose restart postgres
```

## Security Notes

- Passwords are hashed using bcryptjs (10 rounds)
- Sessions use secure httpOnly cookies
- User IDs (UUIDs) are used as OAuth2 subjects
- Hydra manages OAuth2 tokens and consent sessions

## Integration with Hydra

Auth.zoo acts as the login/consent provider for Hydra:

- Login URL: `https://auth.zoo/login`
- Consent URL: `https://auth.zoo/consent`
- Logout URL: `https://auth.zoo/logout`
- Error URL: `https://auth.zoo/error`

OAuth2 clients are defined in `core/hydra/clients/` and created by Hydra's startup script.
