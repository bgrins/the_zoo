# Alternative Email Testing Setup

Since setting up Stalwart with custom admin credentials is proving complex, here's an alternative approach:

## Option 1: Use a Test Email Service

Instead of using Stalwart, we can configure SnappyMail to use a test email service or create a mock email server.

## Option 2: Fix Stalwart Configuration

The issue is that Stalwart is trying to load a corrupted configuration. To fix:

1. Stop Stalwart completely
2. Remove all Stalwart data
3. Start fresh without any volume mounts
4. Get the generated admin password from logs
5. Use that to create users via API

## Option 3: Direct Database User Creation

Since Stalwart uses RocksDB or PostgreSQL, we could potentially:

1. Create users directly in the database
2. Or use a SQL-based authentication backend

## Current Status

- SnappyMail is correctly configured and ready
- The zoo domain is set up with STARTTLS on ports 143/587
- The only missing piece is creating user accounts in Stalwart

## Temporary Solution

For now, the email infrastructure is ready. Once you have:

1. A working Stalwart instance with known admin credentials
2. Or switch to a different email server (like Maddy, Postfix+Dovecot, etc.)

The SnappyMail webmail interface will work immediately.
