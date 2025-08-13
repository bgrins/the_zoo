#!/bin/bash
# Script to create a golden backup of SnappyMail configuration
# This backs up only the essential config files, not user data

set -e

BACKUP_DIR="data-golden"
DATA_DIR="data"

echo "Creating golden backup of SnappyMail configuration..."

# Create backup directory
mkdir -p "$BACKUP_DIR/_data_/_default_"

# Copy essential configuration files
echo "Backing up configuration files..."
cp -p "$DATA_DIR/_data_/_default_/configs/application.ini" "$BACKUP_DIR/_data_/_default_/" 2>/dev/null || true

# Copy domain configurations
echo "Backing up domain configurations..."
mkdir -p "$BACKUP_DIR/_data_/_default_/domains"
cp -p "$DATA_DIR/_data_/_default_/domains/"*.json "$BACKUP_DIR/_data_/_default_/domains/" 2>/dev/null || true
cp -p "$DATA_DIR/_data_/_default_/domains/"*.ini "$BACKUP_DIR/_data_/_default_/domains/" 2>/dev/null || true

# Copy essential files (but not user data)
echo "Backing up essential files..."
cp -p "$DATA_DIR/.htaccess" "$BACKUP_DIR/" 2>/dev/null || true
cp -p "$DATA_DIR/SALT.php" "$BACKUP_DIR/" 2>/dev/null || true

# Create a restore script
cat > "$BACKUP_DIR/RESTORE.md" << 'EOF'
# SnappyMail Golden Configuration Restore

To restore this configuration to a fresh SnappyMail installation:

1. Ensure the container has started at least once to create the data structure
2. Copy the configuration files:
   ```bash
   docker cp data-golden/_data_/_default_/configs/application.ini CONTAINER_NAME:/var/lib/snappymail/_data_/_default_/configs/
   docker cp data-golden/_data_/_default_/domains/ CONTAINER_NAME:/var/lib/snappymail/_data_/_default_/
   ```

3. Restart the container

## What's Included:
- Admin configuration (application.ini)
- Domain configurations (zoo.json, stalwart.ini, etc.)
- Security files (.htaccess, SALT.php)

## What's NOT Included:
- User emails
- User settings
- Contact databases
- Cache files
- Session data
EOF

echo "Golden backup created in $BACKUP_DIR/"
echo "Configuration files backed up. User data is NOT included."