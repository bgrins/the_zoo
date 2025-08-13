FROM ghcr.io/the-djmaze/snappymail:v2.38.2

# Install necessary packages for configuration
RUN apk add --no-cache jq curl

# Copy custom entrypoint and config
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY config/ /config/

# Copy golden configuration if it exists
COPY data-golden/ /var/lib/snappymail-golden/

RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/entrypoint.sh"]
