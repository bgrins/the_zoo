FROM stalwartlabs/mail-server:v0.11.8

# Install useful debugging tools
RUN apt-get update && apt-get install -y netcat-openbsd curl jq swaks && rm -rf /var/lib/apt/lists/*

# Copy configuration and startup script
COPY config.toml /usr/local/bin/config.toml
COPY startup.sh /usr/local/bin/startup.sh
COPY create-users.sh /usr/local/bin/create-users.sh
RUN chmod +x /usr/local/bin/startup.sh /usr/local/bin/create-users.sh

# Expose ports for SMTP, IMAP, and admin interface
EXPOSE 25 587 993 143 8080

# Use our startup script
ENTRYPOINT ["/usr/local/bin/startup.sh"]
