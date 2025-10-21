FROM golang:1.18-alpine AS builder

WORKDIR /app

# Instalar dependencias necesarias
RUN apk add --no-cache git build-base

# Copiar los archivos de módulos
COPY go.mod go.sum* ./
RUN if [ -f go.sum ]; then go mod download; fi

# Copiar código fuente
COPY . .

# Si no existe go.sum, hacer tidy
RUN if [ ! -f go.sum ]; then go mod tidy; fi

# Construir la aplicación
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