#!/bin/bash
set -e

# Get the proxy port
PROXY_PORT=$(docker compose ps proxy --format json | jq -r '.Publishers[0].PublishedPort')

echo "Testing Gitea OpenID integration..."
echo "Proxy port: $PROXY_PORT"
echo

# Test that Gitea is accessible
echo "1. Testing Gitea is accessible..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" --proxy http://localhost:$PROXY_PORT http://gitea.zoo/

# Test that auth.zoo is accessible
echo
echo "2. Testing auth.zoo is accessible..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" --proxy http://localhost:$PROXY_PORT http://auth.zoo/

# Test OpenID discovery endpoint
echo
echo "3. Testing OpenID discovery endpoint..."
curl -s --proxy http://localhost:$PROXY_PORT http://auth.zoo/.well-known/openid-configuration | jq -r '.issuer'

# Check if OAuth2 provider is configured in Gitea
echo
echo "4. Checking OAuth2 providers in Gitea..."
docker compose exec gitea-zoo su git -c "gitea admin auth list"

echo
echo "To test the login flow manually:"
echo "1. Open http://gitea.zoo in the zoo-playwright browser"
echo "2. Click 'Sign In'"
echo "3. You should see an 'auth.zoo' option"
echo "4. Click it to authenticate via auth.zoo"
echo "5. Use credentials: alice/alice123 or bob/bob123"