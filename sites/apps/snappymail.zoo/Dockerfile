FROM ghcr.io/the-djmaze/snappymail:v2.38.2

# Install necessary packages for configuration
RUN apk add --no-cache jq curl

# Copy custom entrypoint and config
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY config/ /config/

# Golden /var/lib/snappymail (a volume, restored when postgres is): the image's own files there
# plus the captured configuration
RUN cp -a /var/lib/snappymail /var/lib/snappymail-golden
COPY data-golden/ /var/lib/snappymail-golden/

RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/entrypoint.sh"]
