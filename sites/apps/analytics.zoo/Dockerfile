FROM matomo:5.5.1

# Golden config, copied into the emptied /var/www/html on every start by core/follow-restore.sh
# (see docker-compose.yaml). The image's entrypoint then copies in the Matomo code.
COPY data-golden /golden-data
