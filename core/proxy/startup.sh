#!/bin/bash
set -e

# Remove any stale PID file
rm -f /run/squid.pid

# Ensure log directory has proper permissions
if [ -d "/var/log/squid" ]; then
    # Make the directory writable for the proxy user
    chmod -R 777 /var/log/squid || true
fi

# Check if PROXY_USER and PROXY_PASS are set
if [ -n "$PROXY_USER" ] && [ -n "$PROXY_PASS" ]; then
    echo "Proxy credentials found - enabling authentication"

    # Create htpasswd file for Squid authentication
    htpasswd -bc /etc/squid/passwords "$PROXY_USER" "$PROXY_PASS"
    chmod 644 /etc/squid/passwords
else
    echo "No proxy credentials - disabling authentication"

    # Modify squid.conf to allow unauthenticated access
    sed -i 's/^http_access allow authenticated zoo_domains/http_access allow zoo_domains/' /etc/squid/squid.conf
fi

# Start squid normally
exec /usr/sbin/squid -f /etc/squid/squid.conf -N
