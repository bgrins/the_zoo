FROM ubuntu/squid:latest

RUN apt-get update && apt-get install -y \
    dnsutils \
    curl \
    iputils-ping \
    apache2-utils \
    && rm -rf /var/lib/apt/lists/*

COPY squid.conf /etc/squid/squid.conf
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Override the entrypoint to use our startup script
ENTRYPOINT ["/startup.sh"]
