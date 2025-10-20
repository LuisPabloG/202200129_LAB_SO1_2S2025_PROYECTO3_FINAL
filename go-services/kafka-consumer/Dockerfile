FROM golang:1.21 AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /kafka-consumer

FROM alpine:latest
WORKDIR /app
COPY --from=builder /kafka-consumer .

CMD ["./kafka-consumer"]