FROM mysql:8.1

# Copy seed data
COPY seed/ /docker-entrypoint-initdb.d/

ENV MYSQL_ROOT_PASSWORD=password
ENV MYSQL_DATABASE=analytics_db
ENV MYSQL_USER=analytics_user
ENV MYSQL_PASSWORD=analytics_pw
