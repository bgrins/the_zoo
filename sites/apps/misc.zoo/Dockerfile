FROM golang:1.23-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY main.go .
RUN go build -ldflags="-s -w" -o misc main.go

FROM alpine:3.21
WORKDIR /app
COPY --from=builder /app/misc .
EXPOSE 3000
CMD ["./misc"]
