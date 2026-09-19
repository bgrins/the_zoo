#!/bin/bash
set -e

# Remove any stale PID file
rm -f /run/squid.pid

# Squid logs to the container's stdout/stderr pipes, which it reopens after dropping
# privileges to the proxy user. The pipes are root-owned 0600, so open them up; cache_log
# opens with "a+", which needs read access too.
chmod o+rw /proc/self/fd/1 /proc/self/fd/2 ||
    echo "WARNING: could not open stdout/stderr to the proxy user; Squid may not log"

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
    sed -i 's/^http_access allow authenticated external_domains/http_access allow external_domains/' /etc/squid/squid.conf
fi

# Start squid normally
exec /usr/sbin/squid -f /etc/squid/squid.conf -N
