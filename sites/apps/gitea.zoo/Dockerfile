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

# Copy prepared git repositories to a safe location (not /data, since that's a VOLUME)
# The entrypoint will copy them to /data/git/repositories when the container starts
COPY --from=fetcher /app/gitea-repos /app/git-repositories-image
RUN chown -R git:git /app/git-repositories-image

# Copy runtime configuration scripts
COPY configure-oauth.sh /app/
COPY create-users.sh /app/
COPY import-repos.sh /app/
COPY sample-data/ /app/sample-data/
RUN chmod +x /app/configure-oauth.sh /app/create-users.sh /app/import-repos.sh

# Copy golden state data (config, JWT keys, avatars)
COPY data-golden/ /golden-data/
RUN chown -R git:git /golden-data

# Patch upstream Gitea templates for .zoo domains at build time instead of
# storing full template copies that drift on version bumps.
# gitea embedded extract preserves the templates/ prefix, so extracting into
# /golden-data/gitea/ lands files at /golden-data/gitea/templates/*.
RUN su-exec git gitea embedded extract --destination /golden-data/gitea \
        templates/home.tmpl templates/base/head_navbar.tmpl \
    && sed -i 's|https://docs.gitea.com|https://docs.gitea.zoo|g' \
        /golden-data/gitea/templates/base/head_navbar.tmpl \
    && sed -i 's|{{ctx.Locale.Tr "startpage.install_desc" "[^"]*" "[^"]*" "[^"]*"}}|Browse local examples on <a href="https://gitea.zoo/explore/repos">gitea.zoo</a>, ship with <a href="https://gitea.zoo/charlie/zoo-docker-templates">Zoo Docker Templates</a>, or start from <a href="https://gitea.zoo/alice/hello-zoo">hello-zoo</a>.|' \
        /golden-data/gitea/templates/home.tmpl \
    && sed -i 's|{{ctx.Locale.Tr "startpage.license_desc" "[^"]*" "[^"]*" "[^"]*"}}|Explore open source projects on <a href="https://gitea.zoo/explore/repos">gitea.zoo</a> and contribute through repos like <a href="https://gitea.zoo/community/awesome-zoo">community/awesome-zoo</a>.|' \
        /golden-data/gitea/templates/home.tmpl

# Override the entrypoint to run OAuth configuration after Gitea starts
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
