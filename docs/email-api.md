# Email API and Operations

Guide to working with email in The Zoo environment.

## Overview

The Zoo provides a complete email infrastructure:

- **Stalwart Mail Server** - SMTP/IMAP server (`stalwart:25` for SMTP, `stalwart:143` for IMAP)
- **SnappyMail** - Webmail client at `http://snappymail.zoo`
- **Email Domain** - All users have `@snappymail.zoo` addresses

## Email Accounts

### Automatic Creation

Email accounts are created automatically when you seed personas or load a universe:

```bash
# Create accounts for all personas
npm run seed

# Or load a specific universe
npm run universe:load default
```

Email format: `{username}@snappymail.zoo` (e.g., `alice@snappymail.zoo` with password `alice123`)

### Manual Creation

Create individual accounts via Stalwart API or CLI:

```bash
# Using CLI (if implemented)
npm run cli -- email create-user --username john --password secret123

# Using API directly
curl -k --proxy http://localhost:3128 \
  -X POST https://mail-api.zoo/api/principal \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n 'admin:zoo-mail-admin-pw' | base64)" \
  -d '{
    "type": "individual",
    "name": "john@snappymail.zoo",
    "description": "John Doe",
    "secrets": ["secret123"],
    "emails": ["john@snappymail.zoo"],
    "quota": 0,
    "roles": ["user"]
  }'
```

### List Accounts

```bash
npm run cli -- email users
```

## Sending Email

### Method 1: CLI (Recommended)

Send email via CLI wrapper around `swaks`:

```bash
# Basic email
npm run cli -- email swaks \
  --from alice@snappymail.zoo \
  --to bob@snappymail.zoo \
  --server stalwart:25 \
  --header "Subject: Hello Bob" \
  --body "This is a test email"

# Multiple recipients
npm run cli -- email swaks \
  --from alice@snappymail.zoo \
  --to bob@snappymail.zoo,charlie@snappymail.zoo \
  --server stalwart:25 \
  --header "Subject: Team Update" \
  --body "Hello team!"

# HTML email
npm run cli -- email swaks \
  --from alice@snappymail.zoo \
  --to bob@snappymail.zoo \
  --server stalwart:25 \
  --header "Subject: HTML Test" \
  --header "Content-Type: text/html" \
  --body "<h1>Hello</h1><p>This is HTML</p>"
```

### Method 2: Docker Exec

Send directly via SMTP inside the Stalwart container:

```bash
docker compose exec -T stalwart swaks \
  --from alice@snappymail.zoo \
  --to bob@snappymail.zoo \
  --server localhost:25 \
  --header "Subject: Direct SMTP" \
  --body "Sent directly via SMTP"
```

### Method 3: Via Universes

Define emails in universe JSON files to send automatically on load. Basic example:

```json
{
  "from": "alice@snappymail.zoo",
  "to": "bob@snappymail.zoo",
  "subject": "Project Update",
  "body": "The project is complete!"
}
```

Universe emails support multiple recipients, HTML content, timestamps, and CC fields. See [Universe Reference](./universe-reference.md#email-schema) for complete schema.

## Reading Email

### Method 1: Webmail (SnappyMail)

1. Navigate to `http://snappymail.zoo`
2. Login with email address and password (e.g., `alice@snappymail.zoo` / `alice123`)
3. Read and manage emails in the web interface

### Method 2: CLI

Check inbox via IMAP:

```bash
npm run cli -- email inbox \
  --user alice@snappymail.zoo \
  --password alice123 \
  --limit 10
```

### Method 3: Browser Automation

Use Playwright for programmatic access:

```typescript
import { chromium } from "playwright";

const browser = await chromium.launch({
  proxy: { server: "http://localhost:3128" },
});

const page = await browser.newPage();
await page.goto("http://snappymail.zoo");
await page.fill('input[name="Email"]', "alice@snappymail.zoo");
await page.fill('input[name="Password"]', "alice123");
await page.click(".buttonLogin");

// Now interact with emails
```

## Server Configuration

### SMTP Details

- **Host**: `stalwart` (inside Docker) or via proxy from host
- **Port**: `25`
- **Auth**: Not required for internal sending
- **TLS**: Disabled (development environment)

### IMAP Details

- **Host**: `stalwart`
- **Port**: `143`
- **Auth**: Username/password required
- **TLS**: Disabled (development environment)

### Accessing from Host

All email operations from the host machine must use the proxy:

```bash
curl -k --proxy http://localhost:3128 https://mail-api.zoo/...
```

Or run commands inside Docker network:

```bash
docker compose exec stalwart swaks ...
```

## Troubleshooting

**Emails not appearing:**

1. Verify Stalwart is running: `docker compose ps stalwart`
2. Check logs: `docker compose logs stalwart --tail 50`
3. Verify account exists: `npm run cli -- email users | grep alice`
4. Wait 1-2 seconds for delivery

**Can't login to SnappyMail:**

- Ensure account exists (run `npm run seed` first)
- Use full email as username: `alice@snappymail.zoo`
- Check password in `scripts/seed-data/personas.ts`

**SMTP connection refused:**

- Use proxy: `--proxy http://localhost:3128`
- Or run inside Docker: `docker compose exec stalwart ...`
- Check Stalwart health: `docker compose ps stalwart`

## Integration Examples

### Testing Email Workflows

```bash
# Send test email
npm run cli -- email swaks \
  --from alice@snappymail.zoo \
  --to bob@snappymail.zoo \
  --server stalwart:25 \
  --header "Subject: Test $(date)" \
  --body "Automated test"

# Wait for delivery
sleep 2

# Verify receipt
npm run cli -- email inbox \
  --user bob@snappymail.zoo \
  --password bob123 \
  --limit 1
```

### Bulk Email Sending

```bash
for i in {1..10}; do
  npm run cli -- email swaks \
    --from alice@snappymail.zoo \
    --to bob@snappymail.zoo \
    --server stalwart:25 \
    --header "Subject: Bulk email $i" \
    --body "Message number $i"
done
```

### SMTP Integration in Apps

Services can send emails programmatically via SMTP:

```typescript
// Using nodemailer or similar
const transporter = nodemailer.createTransport({
  host: "stalwart",
  port: 25,
  secure: false,
});

await transporter.sendMail({
  from: "noreply@auth.zoo",
  to: "user@snappymail.zoo",
  subject: "Password Reset",
  text: "Click here to reset...",
});
```

## API Reference

### Stalwart Admin API

Base URL: `https://mail-api.zoo/api`
Auth: Basic with `admin:zoo-mail-admin-pw`

**Key endpoints:**

- `POST /api/principal` - Create user/domain
- `GET /api/principal` - List principals
- `DELETE /api/principal/{name}` - Delete user

Full API docs: [Stalwart API Documentation](https://stalw.art/docs/api/management/overview)

### CLI Commands

```bash
npm run cli -- email --help
```

Available subcommands:

- `swaks` - Send email via SMTP
- `inbox` - Read inbox via IMAP
- `users` - List email accounts

## See Also

- [Universe Reference](./universe-reference.md) - Email schema for universes
- [Universe CLI Reference](./universe-cli-reference.md) - CLI commands for adding emails to universes
- [Creating Universes](./creating-universes.md) - Tutorial with email examples
- [Stalwart Documentation](https://stalw.art/docs/) - Full mail server docs
