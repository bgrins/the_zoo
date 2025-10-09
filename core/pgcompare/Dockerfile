# syntax=docker/dockerfile:1

ARG PGCOMPARE_VERSION=v0.4.0

# ---- build stage ----
FROM maven:3.9-eclipse-temurin-21 AS build
ARG PGCOMPARE_VERSION

WORKDIR /src
# Pull a specific tag’s source tarball so we don’t need a local checkout
ADD https://github.com/CrunchyData/pgCompare/archive/refs/tags/${PGCOMPARE_VERSION}.tar.gz /tmp/src.tar.gz
RUN tar -xzf /tmp/src.tar.gz --strip-components=1 && \
    mvn -q -DskipTests clean package

# ---- runtime stage ----
FROM eclipse-temurin:21-jre
# Match upstream envs/paths
ENV PGCOMPARE_HOME=/opt/pgcompare \
    PGCOMPARE_CONFIG=/etc/pgcompare/pgcompare.properties \
    PATH=/opt/pgcompare:$PATH
WORKDIR /opt/pgcompare

# copy the compiled app
COPY --from=build /src/target/ /opt/pgcompare/

# simple entrypoint similar to upstream 'start.sh'
# lets you run: `docker run ... compare --batch 0 -r /out/report.html`
ENTRYPOINT ["java","-jar","/opt/pgcompare/pgcompare.jar"]
CMD ["--help"]
