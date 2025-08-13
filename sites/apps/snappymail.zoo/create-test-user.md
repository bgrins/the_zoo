# Creating Email Users in Stalwart

Since Stalwart's newer version doesn't have a simple CLI command to create users, here are the methods to create email accounts:

## Method 1: Using OAuth/Basic Auth API (Requires Admin Password)

The admin password is stored as a hash in `/opt/stalwart-mail/etc/config.toml`. Without knowing the original password, we can't use the API directly.

## Method 2: Direct Configuration (Recommended for Testing)

For testing purposes, you can add a test user by modifying Stalwart's configuration:

1. Create a custom configuration file with test users
2. Mount it into the Stalwart container
3. Restart Stalwart

## Method 3: Using External Authentication

Configure Stalwart to use an external authentication source like LDAP or SQL database.

## For now, here's what we know:

1. **IMAP** is running on port 143 (requires STARTTLS)
2. **SMTP** is running on port 587 (requires STARTTLS)
3. **Admin interface** API is on port 8080
4. The admin user exists but the password is hashed

## Testing Connection without User

You can verify SnappyMail's connection to Stalwart is working by:

1. Checking the domain configuration is correct (✓ Already done)
2. Verifying network connectivity (✓ IMAP/SMTP respond)
3. Testing with a real user account (pending)

## Next Steps

To properly set up user accounts, we should:

1. Reset the admin password in Stalwart configuration
2. Use the API to create users programmatically
3. Or configure Stalwart with a simpler authentication backend

For production use, you would typically:

- Set up Stalwart with proper admin credentials during initial deployment
- Use the web admin interface or API to manage users
- Integrate with existing user directories (LDAP, Active Directory, etc.)
