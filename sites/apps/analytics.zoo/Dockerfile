FROM matomo:5.5.1

# Copy golden state config if it exists
COPY data-golden /golden-data

# Use custom entrypoint that restores golden state on first start
COPY entrypoint.sh /entrypoint-wrapper.sh
RUN chmod +x /entrypoint-wrapper.sh

ENTRYPOINT ["/entrypoint-wrapper.sh"]
CMD ["apache2-foreground"]
