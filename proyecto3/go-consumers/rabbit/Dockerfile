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
RUN CGO_ENABLED=1 GOOS=linux go build -a -o rabbitmq-consumer .

FROM alpine:latest

RUN apk add --no-cache ca-certificates

WORKDIR /root/

COPY --from=builder /app/rabbitmq-consumer .

ENV RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672/
ENV RABBITMQ_QUEUE=weather-tweets
ENV REDIS_ADDR=valkey:6379
ENV REDIS_PASSWORD=""
ENV REDIS_DB=0

CMD ["./rabbitmq-consumer"]