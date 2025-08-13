FROM ghcr.io/kiwix/kiwix-serve:3.7.0

RUN apk add --no-cache curl

# Download Simple English Wikipedia ZIM file (no images)
# Source: https://download.kiwix.org/zim/wikipedia/wikipedia_en_simple_all_nopic_2024-06.zim
# Cached at: https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/wiki/simple-en/wikipedia_en_simple_all_nopic_2024-06.zim
ARG ZIM_URL=https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/wiki/simple-en/wikipedia_en_simple_all_nopic_2024-06.zim
ARG ZIM_FILE=wikipedia_en_simple_all_nopic_2024-06.zim

# Create data directory
RUN mkdir -p /data

# Download the ZIM file - force fresh download (915MB expected)
# Using a specific file ensures this layer is cached unless the URL changes
RUN curl -L -o "/data/${ZIM_FILE}" "${ZIM_URL}" && \
    echo "Downloaded ${ZIM_FILE}" && \
    ls -lh /data/

# Verify the ZIM file was copied successfully
RUN ls -la /data/ && \
    echo "ZIM file size: $(stat -c%s /data/wikipedia_en_simple_all_nopic_2024-06.zim) bytes"

# Copy the custom index.html for auto-redirect and library.xml
COPY index.html /data/
