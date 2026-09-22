# The output is static HTML, so build on the native platform (avoids slow QEMU emulation in CI).
FROM --platform=$BUILDPLATFORM node:22.23.2-alpine AS build

ARG GITEA_DOCS_REPO=https://gitea.com/gitea/docs.git
ARG GITEA_DOCS_REF=c78e0d42a9d885010d1b1e756c16672ad8227bd6
ARG AWESOME_GITEA_REPO=https://gitea.com/gitea/awesome-gitea.git
ARG AWESOME_GITEA_REF=7535fa0448a93af02bbc6076e752e5a230fc3bca

ENV NODE_OPTIONS=--max-old-space-size=8192

WORKDIR /src

RUN apk add --no-cache git make

RUN git init . \
    && git remote add origin "${GITEA_DOCS_REPO}" \
    && git fetch --depth 1 origin "${GITEA_DOCS_REF}" \
    && git checkout FETCH_HEAD

RUN mkdir -p /tmp/upstream-awesome \
    && cd /tmp/upstream-awesome \
    && git init . \
    && git remote add origin "${AWESOME_GITEA_REPO}" \
    && git fetch --depth 1 origin "${AWESOME_GITEA_REF}" \
    && git checkout FETCH_HEAD

RUN for dir in docs versioned_docs/version-*; do \
        cp /tmp/upstream-awesome/README.md "$dir/awesome.md"; \
    done

COPY patch-config.mjs /usr/local/bin/patch-config.mjs

RUN node /usr/local/bin/patch-config.mjs

RUN corepack enable \
    && pnpm install --frozen-lockfile \
    && pnpm run build-CSRApi

FROM nginx:1.30.5-alpine

COPY --from=build /src/build/ /usr/share/nginx/html/

EXPOSE 80
