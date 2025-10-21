FROM golang:1.18-alpine AS builder

WORKDIR /app

COPY go.mod ./
RUN apk add --no-cache build-base
RUN go mod download

COPY . .

RUN CGO_ENABLED=1 GOOS=linux go build -a -o kafka-consumer .

FROM alpine:latest  

RUN apk add --no-cache librdkafka-dev

WORKDIR /root/

COPY --from=builder /app/kafka-consumer .

ENV KAFKA_BROKERS=kafka:9092
ENV KAFKA_TOPIC=weather-tweets
ENV KAFKA_GROUP=weather-consumer-group
ENV REDIS_ADDR=valkey:6379
ENV REDIS_PASSWORD=
ENV REDIS_DB=0

CMD ["./kafka-consumer"]