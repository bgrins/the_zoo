FROM gitea/gitea:1.24.2 AS fetcher

# Install required tools
USER root
RUN apk add --no-cache jq curl git

# Fetch git repositories during build
COPY fetch-repos.sh /app/
RUN chmod +x /app/fetch-repos.sh && /app/fetch-repos.sh

# Prepare git repositories for Gitea
COPY prepare-repos.sh /app/
RUN chmod +x /app/prepare-repos.sh && /app/prepare-repos.sh

# Main stage
FROM gitea/gitea:1.24.2

# Install required tools
USER root
RUN apk add --no-cache jq curl git

# Copy prepared git repositories to Gitea's repository location
COPY --from=fetcher /app/gitea-repos /data/git/repositories
RUN chown -R git:git /data/git/repositories

# Copy runtime configuration scripts
COPY configure-oauth.sh /app/
COPY create-users.sh /app/
COPY import-repos.sh /app/
COPY sample-data/ /app/sample-data/
RUN chmod +x /app/configure-oauth.sh /app/create-users.sh /app/import-repos.sh

# Override the entrypoint to run OAuth configuration after Gitea starts
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
