FROM node:22-alpine AS build

ARG GITEA_DOCS_REPO=https://gitea.com/gitea/docs.git
ARG GITEA_DOCS_REF=eb8ade10c72f697dcc05628b9bd8b1a185f5a4c5
ARG AWESOME_GITEA_REPO=https://gitea.com/gitea/awesome-gitea.git
ARG AWESOME_GITEA_REF=a2c1cc40de0dfaa83981ab19c7789414aa5ca10a

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

RUN cp /tmp/upstream-awesome/README.md docs/awesome.md \
    && cp /tmp/upstream-awesome/README.md versioned_docs/version-1.22/awesome.md \
    && cp /tmp/upstream-awesome/README.md versioned_docs/version-1.23/awesome.md \
    && cp /tmp/upstream-awesome/README.md versioned_docs/version-1.24/awesome.md \
    && cp /tmp/upstream-awesome/README.md versioned_docs/version-1.25/awesome.md

COPY patch-config.mjs /usr/local/bin/patch-config.mjs

RUN node /usr/local/bin/patch-config.mjs

RUN corepack enable \
    && pnpm install --frozen-lockfile \
    && pnpm run build-CSRApi

FROM nginx:1.27-alpine

COPY --from=build /src/build/ /usr/share/nginx/html/

EXPOSE 80
