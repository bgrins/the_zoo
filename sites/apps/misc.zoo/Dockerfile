# Cross-compile on the native build platform (avoids slow QEMU emulation in CI).
FROM --platform=$BUILDPLATFORM golang:1.23-alpine AS builder
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY main.go .
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags="-s -w" -o misc main.go

FROM alpine:3.21
WORKDIR /app
COPY --from=builder /app/misc .
EXPOSE 3000
CMD ["./misc"]
