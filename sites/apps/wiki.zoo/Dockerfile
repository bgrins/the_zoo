FROM ghcr.io/kiwix/kiwix-serve:3.7.0

USER root
RUN apk add --no-cache curl

# Download Simple English Wikipedia ZIM file (no images)
# Source: https://download.kiwix.org/zim/wikipedia/wikipedia_en_simple_all_nopic_2024-06.zim
# Cached at: https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/wiki/simple-en/wikipedia_en_simple_all_nopic_2024-06.zim
ARG ZIM_URL=https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/wiki/simple-en/wikipedia_en_simple_all_nopic_2024-06.zim
ARG ZIM_FILE=wikipedia_en_simple_all_nopic_2024-06.zim
ARG ZIM_SHA256=5d2081e39c54caff1aa6fb1450cdec20ef902d09e40f1872fe580c0aac1a5a78

# Create data directory
RUN mkdir -p /data

# Download the ZIM file (915MB). -f fails on HTTP errors instead of saving the error page.
RUN curl -fL -o "/data/${ZIM_FILE}" "${ZIM_URL}" && \
    echo "${ZIM_SHA256}  /data/${ZIM_FILE}" | sha256sum -c -

# Copy the custom index.html for auto-redirect and library.xml
COPY index.html /data/
