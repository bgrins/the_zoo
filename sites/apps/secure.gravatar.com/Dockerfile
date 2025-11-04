FROM golang:1.23-alpine AS builder

WORKDIR /app
COPY main.go .
RUN go build -ldflags="-s -w" -o gravatar main.go

FROM alpine:3.21
WORKDIR /app
COPY --from=builder /app/gravatar .
EXPOSE 8080
CMD ["./gravatar"]
