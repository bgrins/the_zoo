#!/bin/bash
set -e

# Remove any stale PID file
rm -f /run/squid.pid

# Ensure log directory has proper permissions
if [ -d "/var/log/squid" ]; then
    # Make the directory writable for the proxy user
    chmod -R 777 /var/log/squid || true
fi

# Multi-agent mode: PROXY_USERS="name:pass,name:pass,..."
# Each user gets a dedicated outgoing IP (172.20.251.101, .102, ...) via
# tcp_outgoing_address, so downstream services (Caddy) can attribute traffic
# to an agent by source IP. Authentication is required in this mode.
if [ -n "$PROXY_USERS" ]; then
    echo "PROXY_USERS set - enabling per-agent authentication and outgoing IPs"

    # Find the interface on the zoo network (172.20.0.0/16)
    ZOO_IFACE=$(ip -o -4 addr show | awk '/inet 172\.20\./ {print $2; exit}')
    echo "Zoo network interface: $ZOO_IFACE"

    rm -f /etc/squid/passwords
    touch /etc/squid/passwords
    chmod 644 /etc/squid/passwords

    {
        echo ""
        echo "# Per-agent outgoing addresses (appended by startup.sh)"
    } >> /etc/squid/squid.conf

    i=0
    for entry in $(echo "$PROXY_USERS" | tr ',' ' '); do
        user="${entry%%:*}"
        pass="${entry#*:}"
        agent_ip="172.20.251.$((101 + i))"

        htpasswd -b /etc/squid/passwords "$user" "$pass"
        ip addr add "$agent_ip/32" dev "$ZOO_IFACE" 2>/dev/null || true
        echo "Agent '$user' -> outgoing IP $agent_ip"

        {
            echo "acl agent_${user} proxy_auth ${user}"
            echo "tcp_outgoing_address ${agent_ip} agent_${user}"
        } >> /etc/squid/squid.conf

        i=$((i + 1))
    done
else
    echo "No proxy credentials - disabling authentication"

    # Modify squid.conf to allow unauthenticated access
    sed -i 's/^http_access allow authenticated zoo_domains/http_access allow zoo_domains/' /etc/squid/squid.conf
    sed -i 's/^http_access allow authenticated external_domains/http_access allow external_domains/' /etc/squid/squid.conf
fi

# Start squid normally
exec /usr/sbin/squid -f /etc/squid/squid.conf -N
