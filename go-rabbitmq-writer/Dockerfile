FROM golang:1.23-alpine AS builder
RUN apk add --no-cache git protobuf-dev
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o rabbitmq-writer main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/rabbitmq-writer .
EXPOSE 50052
CMD ["./rabbitmq-writer"]
