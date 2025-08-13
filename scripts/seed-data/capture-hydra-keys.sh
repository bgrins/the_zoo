#!/bin/bash
# Capture Hydra's auto-generated keys into the postgres golden state

set -euo pipefail

# Force recreate containers to start fresh
docker compose up -d postgres hydra --force-recreate

# Wait for services to be healthy
sleep 15

# Test that keys are working
curl -k --proxy http://localhost:3128 http://auth.zoo/.well-known/openid-configuration

# Capture the current auth database state with keys
docker exec thezoo-postgres-1 pg_dump -U auth_user auth_db > core/postgres/seed/auth.sql

# Rebuild postgres container to include new golden state
docker compose build postgres

echo "Done! Auth database golden state captured with Hydra keys."