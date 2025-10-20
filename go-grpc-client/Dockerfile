FROM golang:1.21-alpine AS builder
RUN apk add --no-cache git protobuf-dev
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o grpc-client main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/grpc-client .
EXPOSE 8080
CMD ["./grpc-client"]
