FROM golang:1.18-alpine AS builder

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -o rabbit-consumer .

FROM alpine:latest  

WORKDIR /root/

COPY --from=builder /app/rabbit-consumer .

ENV RABBIT_URL=amqp://guest:guest@rabbitmq:5672/
ENV RABBIT_QUEUE=weather-tweets
ENV REDIS_ADDR=valkey:6379
ENV REDIS_PASSWORD=
ENV REDIS_DB=0

CMD ["./rabbit-consumer"]