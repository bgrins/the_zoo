
# Build the database on the native build platform (avoids slow QEMU emulation in CI).
FROM --platform=$BUILDPLATFORM mysql:8.1 AS builder

# Install required packages including xz for decompressing downloaded files
RUN microdnf install -y curl bash xz && \
    microdnf clean all

# Create directory for SQL files
RUN mkdir -p /tmp/sql

# Download SQL files for classifieds app
RUN curl -L https://raw.githubusercontent.com/bgrins/vwa_classifieds_optimized/fb33fea4b701a4eef502488d06267368b9104e90/mysql-baked/classifieds_import.sql -o /tmp/sql/classifieds_import.sql
RUN curl -L https://raw.githubusercontent.com/bgrins/vwa_classifieds_optimized/fb33fea4b701a4eef502488d06267368b9104e90/mysql-baked/classifieds_restore.sql -o /tmp/sql/classifieds_restore.sql

# Download Magento database dump for onestopshop.zoo
RUN curl -L https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/onestopshop/magento_dump.sql.xz -o /tmp/sql/magento_dump.sql.xz && \
    xz -d /tmp/sql/magento_dump.sql.xz

# Copy Northwind database files
COPY seed/northwind-schema.sql /tmp/sql/northwind-schema.sql
COPY seed/northwind-data.sql /tmp/sql/northwind-data.sql

# Copy initialization script
COPY init-databases.sh /usr/local/bin/

# Copy MySQL config for faster bulk imports (only needed during build)
COPY my.cnf /etc/my.cnf

ENV MYSQL_ROOT_PASSWORD=password

# Accept build arg for no seeding
ARG ZOO_NO_SEED=false
ENV ZOO_NO_SEED=$ZOO_NO_SEED

# Initialize MySQL and run database creation script
# Use --skip-log-bin to disable binary logging (saves ~4GB in dev environment)
RUN mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql && \
    mysqld --user=mysql --datadir=/var/lib/mysql --socket=/tmp/mysql.sock --skip-networking --skip-log-bin & \
    pid="$!" && \
    /usr/local/bin/init-databases.sh && \
    echo "Shutting down MySQL..." && \
    mysqladmin -u root --socket=/tmp/mysql.sock shutdown && \
    wait "$pid" && \
    rm -rf /var/lib/mysql/#innodb_redo/* && \
    rm -f /var/lib/mysql/undo_* && \
    cd /var/lib && \
    tar -cf /var/lib/mysql-golden.tar mysql

FROM mysql:8.1

# Copy the uncompressed tar backup (fast extraction)
COPY --from=builder /var/lib/mysql-golden.tar /var/lib/mysql-golden.tar

ENV MYSQL_ROOT_PASSWORD=password

# Add custom entrypoint that resets data on every start
COPY custom-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["mysqld"]
