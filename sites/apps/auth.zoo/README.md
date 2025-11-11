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

Test users are automatically created from `seedData/users.json` when the database is empty:

- **admin** / admin123 - System administrator
- **alice** / alice123 - Developer account
- **bob** / bob123 - Manager account
- **demo** / demo - Demo account
- ...and more (see seedData/users.json)

## Adding Test Users

1. Edit `seedData/users.json`
2. Reset the database: `thezoo db reset auth`
3. The new users will be created on next startup

## API Endpoints

### Public Endpoints

- `GET /` - Homepage
- `GET /register` - Registration page
- `POST /register` - Create new account
- `GET /login` - OAuth2 login flow
- `POST /login` - Process login
- `GET /consent` - OAuth2 consent flow
- `POST /consent` - Process consent

### Authenticated Endpoints

- `GET /dashboard` - User dashboard
- `GET /profile` - Edit profile page
- `POST /profile` - Update profile
- `POST /change-password` - Change password
- `POST /logout` - Logout
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
├── server.js          # Main Express server
├── db.js              # PostgreSQL connection
├── userService.js     # User CRUD operations
├── migrate.js         # Migration runner
├── seedData.js        # Seed data loader
├── migrations/        # SQL migrations
│   └── 001_create_users.sql
└── seedData/          # Test data
    ├── users.json     # Test user accounts
    └── README.md      # Seed data documentation
```

### Environment Variables

- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (default: development)

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

To completely reset auth.zoo (useful for testing):

```bash
# From zoo root directory
thezoo db reset auth
```

This will:

1. Drop the auth_db database
2. Recreate it empty
3. Run migrations on next startup
4. Load seed data from seedData/users.json

## Security Notes

- Passwords are hashed using bcryptjs (10 rounds)
- Sessions use secure httpOnly cookies
- User IDs (UUIDs) are used as OAuth2 subjects
- Hydra manages OAuth2 tokens and consent sessions

## Integration with Hydra

Auth.zoo acts as the login/consent provider for Hydra:

- Login URL: `http://auth.zoo/login`
- Consent URL: `http://auth.zoo/consent`
- Logout URL: `http://auth.zoo/logout`

OAuth2 clients like "zoo-misc-app" are automatically created by Hydra's startup script.
