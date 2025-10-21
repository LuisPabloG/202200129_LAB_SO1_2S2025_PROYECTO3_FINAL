FROM golang:1.18-alpine AS builder

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -o rabbit-writer .

FROM alpine:latest  

WORKDIR /root/

COPY --from=builder /app/rabbit-writer .

ENV PORT=50052
ENV RABBIT_URL=amqp://guest:guest@rabbitmq:5672/
ENV RABBIT_QUEUE=weather-tweets

EXPOSE 50052

CMD ["./rabbit-writer"]