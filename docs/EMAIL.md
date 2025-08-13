# Email System

Stalwart Mail Server + SnappyMail webmail. All passwords: `Password.123`

## Accounts

- **snappymail.zoo**: admin@, user@, alex.chen@, blake.sullivan@
- **zoo**: admin@, user@, test@
- **status.zoo**: admin@, user@

## Quick Commands

```bash
# List users
npm run cli email users

# Check inbox
npm run cli email check --user user@zoo --password Password.123

# Send email (unauthenticated)
npm run cli email swaks -- --to user@zoo --from test@zoo --server stalwart:25 \
  --header "Subject: Test" --body "Test email"

# Send email (authenticated)
npm run cli email swaks -- --to user@zoo --from admin@zoo --server stalwart:587 \
  --tls --auth-user admin@zoo --auth-password Password.123 \
  --header "Subject: Test" --body "Authenticated email"
```

## Access

- **Webmail**: https://snappymail.zoo
- **SMTP**: stalwart:25 (open relay), stalwart:587 (auth required)
- **IMAP**: stalwart:143
