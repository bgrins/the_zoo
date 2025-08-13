FROM ubuntu/squid:latest

RUN apt-get update && apt-get install -y \
    dnsutils \
    curl \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/* \
    && echo '#!/bin/bash\n\
# Remove any stale PID file\n\
rm -f /run/squid.pid\n\
# Ensure log directory has proper permissions\n\
if [ -d "/var/log/squid" ]; then\n\
# Make the directory writable for the proxy user\n\
    chmod -R 777 /var/log/squid || true\n\
fi\n\
# Start squid normally\n\
exec /usr/sbin/squid -f /etc/squid/squid.conf -N' > /startup.sh \
    && chmod +x /startup.sh

COPY squid.conf /etc/squid/squid.conf

# Override the entrypoint to use our startup script
ENTRYPOINT ["/startup.sh"]
