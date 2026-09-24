# Build the database on the native build platform (avoids slow QEMU emulation in CI).
FROM --platform=$BUILDPLATFORM mysql:8.4.11 AS builder

# Downloaded dumps: classifieds app and Magento (onestopshop.zoo, kept compressed and
# streamed into mysql)
ADD --checksum=sha256:78bd0f0515d39876c302e8afe510bae756ef518b3b19a8f172cadcec2f5d6be1 \
    https://raw.githubusercontent.com/bgrins/vwa_classifieds_optimized/fb33fea4b701a4eef502488d06267368b9104e90/mysql-baked/classifieds_import.sql /dumps/classifieds_import.sql
ADD --checksum=sha256:fa6e6879f8926623d0f9287e1add2a27891a92d32e4ca2bc72c838d0cde37f30 \
    https://raw.githubusercontent.com/bgrins/vwa_classifieds_optimized/fb33fea4b701a4eef502488d06267368b9104e90/mysql-baked/classifieds_restore.sql /dumps/classifieds_restore.sql
ADD --checksum=sha256:38eb237b082b8d9dd78e515f6955b4ade0ad1dbbb2611ae8b0b2209edb46884b \
    https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/onestopshop/magento_dump.sql.xz /dumps/magento_dump.sql.xz

# Copy MySQL config for faster bulk imports (only needed during build)
COPY my.cnf /etc/my.cnf

# Accept build arg for no seeding
ARG ZOO_NO_SEED=false
ENV ZOO_NO_SEED=$ZOO_NO_SEED

COPY db-helpers.sh init-external-databases.sh /usr/local/bin/

# Load the downloaded dumps first: this step stays cached when the local seeds change.
# Use --skip-log-bin to disable binary logging (saves ~4GB in dev environment)
RUN mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql && \
    mysqld --user=mysql --datadir=/var/lib/mysql --socket=/tmp/mysql.sock --skip-networking --skip-log-bin & \
    pid="$!" && \
    /usr/local/bin/init-external-databases.sh && \
    echo "Shutting down MySQL..." && \
    mysqladmin -u root --socket=/tmp/mysql.sock shutdown && \
    wait "$pid" && \
# Drop redo and undo logs (recreated on the next start) so this cached layer skips them
    rm -rf /var/lib/mysql/#innodb_redo/* && \
    rm -f /var/lib/mysql/undo_*

COPY seed/northwind-schema.sql seed/northwind-data.sql sql/analytics_seed.sql /tmp/sql/
COPY init-databases.sh /usr/local/bin/

# Load the repo-local seeds on top, then snapshot the data dir into the golden tar.
RUN mysqld --user=mysql --datadir=/var/lib/mysql --socket=/tmp/mysql.sock --skip-networking --skip-log-bin & \
    pid="$!" && \
    /usr/local/bin/init-databases.sh && \
    echo "Shutting down MySQL..." && \
    mysqladmin -u root --socket=/tmp/mysql.sock shutdown && \
    wait "$pid" && \
    rm -rf /var/lib/mysql/#innodb_redo/* && \
    rm -f /var/lib/mysql/undo_* && \
# Create the tar, then drop the live data dir so this layer holds only the tar
    tar -C /var/lib -cf /var/lib/mysql-golden.tar mysql && \
    rm -rf /var/lib/mysql

FROM mysql:8.4.11

# Copy the uncompressed tar backup (fast extraction)
COPY --link --from=builder /var/lib/mysql-golden.tar /var/lib/mysql-golden.tar

# Add custom entrypoint that resets data on every start
COPY custom-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["mysqld"]
