# SnappyMail @ Zoo

SnappyMail is a modern, lightweight webmail client that connects to the Zoo's Stalwart email server.

## Access

- **Webmail Interface**: http://snappymail.zoo
- **Admin Panel**: http://snappymail.zoo/?admin
- **Default Admin Credentials**:
  - Username: `admin`
  - Password: `admin123`

## Features

- Modern web-based email client
- IMAP/SMTP support
- SQLite-based contacts
- Pre-configured for Zoo domain
- Auto-configured connection to Stalwart email server

## Creating Email Accounts

Email accounts must be created in the Stalwart email server first:

1. Access Stalwart admin interface at http://stalwart:8080
2. Create user accounts
3. Users can then log into SnappyMail with their email credentials

## Email Server Settings (Pre-configured)

- **IMAP Server**: stalwart
- **IMAP Port**: 143 (STARTTLS)
- **SMTP Server**: stalwart
- **SMTP Port**: 587 (STARTTLS)
- **Domain**: zoo

## Troubleshooting

### Container Logs

```bash
docker logs snappymail-zoo
```

### Common Issues

1. **Cannot connect to email server**
   - Verify Stalwart is running: `docker ps | grep stalwart`
   - Check network connectivity from SnappyMail container

2. **Admin login not working**
   - Check logs for configuration errors
   - Verify admin credentials were set during startup

3. **Email sending/receiving issues**
   - Verify user account exists in Stalwart
   - Check SMTP/IMAP settings in admin panel

## Development

The SnappyMail container runs with auto-configuration that:

- Sets up the zoo domain
- Configures Stalwart connection
- Creates default admin account
- Enables SQLite contacts

Configuration files are persisted in the `data/` directory.
