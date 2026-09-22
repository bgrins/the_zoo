# Cross-compile on the native build platform (avoids slow QEMU emulation in CI).
FROM --platform=$BUILDPLATFORM golang:1.27.1-alpine3.24 AS builder
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app
COPY main.go .
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags="-s -w" -o gravatar main.go

FROM alpine:3.24.2
WORKDIR /app
COPY --from=builder /app/gravatar .
EXPOSE 8080
CMD ["./gravatar"]
