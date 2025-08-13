# SnappyMail Minimal Golden Data

This directory contains only the essential files needed for SnappyMail to start with proper configuration:

- `SALT.php` - Security salt for encryption
- `INSTALLED` - Marker file to indicate SnappyMail has been installed
- `_data_/_default_/domains/*.json` - Domain configurations for mail servers:
  - `snappymail.zoo.json` - Configuration for snappymail.zoo domain
  - `zoo.json` - Configuration for zoo domain
  - `status.zoo.json` - Configuration for status.zoo domain

## What's NOT included:

- User data (settings, address books) - Created automatically when users first login
- Cache files - Generated as needed
- Application.ini - Created from mounted config directory

This minimal approach ensures a clean start while maintaining essential configurations.
