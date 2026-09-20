# Email System

Stalwart Mail Server + SnappyMail webmail.

## Accounts

| Email                         | Password         |
| ----------------------------- | ---------------- |
| admin@snappymail.zoo          | admin123         |
| user@snappymail.zoo           | snappyuser123    |
| alex.chen@snappymail.zoo      | Password.123     |
| blake.sullivan@snappymail.zoo | Password.123     |
| admin@zoo                     | adminpassword123 |
| user@zoo                      | userpassword123  |
| test@zoo                      | testpassword123  |

Every persona has `<username>@snappymail.zoo` with its persona password (`npm run seed`, listed in `docs/credentials/snappymail.zoo.yaml`). `core/stalwart/create-users.sh` creates the other accounts.

## Commands

```bash
npm run cli -- email users                              # List users
npm run cli -- email inbox --user user@zoo --password userpassword123  # Check inbox
npm run cli -- email swaks --to user@zoo --from test@zoo --server stalwart:25 \
  --header "Subject: Test" --body "Test email"         # Send (unauthenticated)
```

## Access

- Webmail: https://snappymail.zoo
- SMTP: stalwart:25 (open relay), stalwart:587 (auth required)
- IMAP: stalwart:143
