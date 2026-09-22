FROM busybox:1.37.0-musl AS busybox

FROM coredns/coredns:1.14.7

# The coredns image is FROM scratch; add a static busybox so the healthcheck can
# issue a real DNS query instead of only checking that the binary exists.
COPY --from=busybox /bin/busybox /busybox
