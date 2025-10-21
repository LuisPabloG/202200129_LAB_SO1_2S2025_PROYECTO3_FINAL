FROM golang:1.18-alpine AS builder

WORKDIR /app

COPY go.mod ./
RUN apk add --no-cache build-base
RUN go mod download

COPY . .

RUN CGO_ENABLED=1 GOOS=linux go build -a -o kafka-writer .

FROM alpine:latest  

RUN apk add --no-cache librdkafka-dev

WORKDIR /root/

COPY --from=builder /app/kafka-writer .

ENV PORT=50051
ENV KAFKA_BROKERS=kafka:9092
ENV KAFKA_TOPIC=weather-tweets

EXPOSE 50051

CMD ["./kafka-writer"]