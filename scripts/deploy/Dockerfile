FROM docker:27-dind

# Install Node.js, npm, and other essentials
RUN apk add --no-cache \
    nodejs \
    npm \
    bash \
    curl \
    git \
    jq \
    docker-cli-compose

# Create working directory
WORKDIR /zoo

# Install the zoo CLI from npm
RUN npm install -g the_zoo

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set up Docker socket volume
VOLUME /var/run/docker.sock

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
