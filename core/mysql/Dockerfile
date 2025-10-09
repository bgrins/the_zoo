FROM mysql:8.1 AS builder

# Install required packages including xz for snapshot compression
RUN microdnf install -y curl bash xz && \
    microdnf clean all

# Create directory for SQL files
RUN mkdir -p /tmp/sql

# Download SQL files for classifieds app
RUN curl -L https://raw.githubusercontent.com/bgrins/vwa_classifieds_optimized/fb33fea4b701a4eef502488d06267368b9104e90/mysql-baked/classifieds_import.sql -o /tmp/sql/classifieds_import.sql
RUN curl -L https://raw.githubusercontent.com/bgrins/vwa_classifieds_optimized/fb33fea4b701a4eef502488d06267368b9104e90/mysql-baked/classifieds_restore.sql -o /tmp/sql/classifieds_restore.sql

# Copy Northwind database files
COPY seed/northwind-schema.sql /tmp/sql/northwind-schema.sql
COPY seed/northwind-data.sql /tmp/sql/northwind-data.sql

# Copy initialization script
COPY init-databases.sh /usr/local/bin/

ENV MYSQL_ROOT_PASSWORD=password

# Initialize MySQL and run database creation script
RUN mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql && \
    mysqld --user=mysql --datadir=/var/lib/mysql --socket=/tmp/mysql.sock & \
    pid="$!" && \
    /usr/local/bin/init-databases.sh && \
    echo "Shutting down MySQL..." && \
    mysqladmin -u root --socket=/tmp/mysql.sock shutdown && \
    wait "$pid"

FROM mysql:8.1

# Install rsync for faster file copying and xz for decompressing snapshots
RUN microdnf install -y rsync xz && \
    microdnf clean all

# Copy the golden state to a separate directory
COPY --from=builder /var/lib/mysql /var/lib/mysql-golden
# Also copy it to the working directory for first start
COPY --from=builder /var/lib/mysql /var/lib/mysql
# Copy snapshot dumps
COPY --from=builder /var/lib/mysql/snapshots /var/lib/mysql/snapshots

ENV MYSQL_ROOT_PASSWORD=password

# Add custom entrypoint that resets data on every start
COPY custom-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["mysqld"]
