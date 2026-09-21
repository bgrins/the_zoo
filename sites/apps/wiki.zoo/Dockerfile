# syntax=docker/dockerfile:1.14
FROM ghcr.io/kiwix/kiwix-serve:3.7.0

USER root
RUN apk add --no-cache curl

# Download Simple English Wikipedia ZIM file (no images)
# Source: https://download.kiwix.org/zim/wikipedia/wikipedia_en_simple_all_nopic_2024-06.zim
# Cached at: https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/wiki/simple-en/wikipedia_en_simple_all_nopic_2024-06.zim
ARG ZIM_URL=https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/wiki/simple-en/wikipedia_en_simple_all_nopic_2024-06.zim
ARG ZIM_FILE=wikipedia_en_simple_all_nopic_2024-06.zim
ARG ZIM_SHA256=5d2081e39c54caff1aa6fb1450cdec20ef902d09e40f1872fe580c0aac1a5a78

# Download the ZIM file (915MB). BuildKit verifies the checksum, and --link keeps the
# layer independent of the base image, so it survives base bumps and is shared by
# every platform. The symbolic mode (Dockerfile 1.14+, so the syntax line above) also
# applies to the /zim dir the linked layer creates: 755 for it, 644 for the file. Not in the base image's /data volume, which
# would get a copy of it in every container.
ADD --link --chmod=u=rwX,go=rX --checksum=sha256:${ZIM_SHA256} ${ZIM_URL} /zim/${ZIM_FILE}

# Copy the custom index.html for auto-redirect and library.xml
COPY index.html /zim/
WORKDIR /zim
