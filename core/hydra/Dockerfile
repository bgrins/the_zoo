FROM oryd/hydra:v2.2.0

# Switch to root to install dependencies
USER root

# Install jq for JSON parsing in init-clients.sh and curl for API operations
RUN apk add --no-cache jq curl

# Copy startup scripts
COPY --chmod=755 startup.sh /startup.sh
COPY --chmod=755 init-clients.sh /init-clients.sh

# Copy configuration files
COPY hydra.yaml /etc/hydra/hydra.yaml
COPY clients/ /clients/

# Create hydra user and switch to it
RUN adduser -D -s /bin/sh hydra
USER hydra

ENTRYPOINT ["/startup.sh"]
