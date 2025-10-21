FROM golang:1.18-alpine AS builder

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -o go-api .

FROM alpine:latest  

WORKDIR /root/

COPY --from=builder /app/go-api .

ENV PORT=8080
ENV KAFKA_WRITER_ADDR=kafka-writer-service:50051
ENV RABBIT_WRITER_ADDR=rabbit-writer-service:50052

EXPOSE 8080

CMD ["./go-api"]