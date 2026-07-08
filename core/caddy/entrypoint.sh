#!/bin/sh
set -e

# Generate the agent-attribution map from PROXY_USERS ("name:pass,name:pass,...").
# Each user's outgoing IP is 172.20.251.(101 + index), assigned by
# core/proxy/startup.sh using the same ordering, so PROXY_USERS is the single
# source of truth for the roster. Without PROXY_USERS everything maps to
# "anonymous".
{
    echo "# Generated at container start from PROXY_USERS - do not edit"
    echo "map {client_ip} {zoo_agent} {"
    if [ -n "$PROXY_USERS" ]; then
        i=0
        for entry in $(echo "$PROXY_USERS" | tr ',' ' '); do
            user="${entry%%:*}"
            echo "    172.20.251.$((101 + i)) ${user}"
            i=$((i + 1))
        done
    fi
    echo "    default anonymous"
    echo "}"
} > /etc/caddy/zoo-agents.caddy

exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
