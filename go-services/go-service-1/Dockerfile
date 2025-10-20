FROM golang:1.21 AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN mkdir -p proto
COPY ../proto/ ./proto/

# Generar código a partir del proto
RUN apt-get update && apt-get install -y protobuf-compiler
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.30.0
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0
RUN protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative proto/weather.proto

RUN CGO_ENABLED=0 GOOS=linux go build -o /go-service-1

FROM alpine:latest
WORKDIR /app
COPY --from=builder /go-service-1 .

EXPOSE 8080
CMD ["./go-service-1"]