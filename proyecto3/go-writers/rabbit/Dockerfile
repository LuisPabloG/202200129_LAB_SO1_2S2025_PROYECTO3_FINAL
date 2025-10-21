FROM golang:1.18-alpine AS builder

WORKDIR /app

# Instalar dependencias necesarias
RUN apk add --no-cache git

# Copiar los archivos de módulos
COPY go.mod go.sum* ./
RUN if [ -f go.sum ]; then go mod download; fi

# Copiar código fuente
COPY . .

# Si no existe go.sum, hacer tidy
RUN if [ ! -f go.sum ]; then go mod tidy; fi

# Construir la aplicación
RUN CGO_ENABLED=0 GOOS=linux go build -a -o rabbit-writer .

FROM alpine:latest  

WORKDIR /root/

COPY --from=builder /app/rabbit-writer .

ENV PORT=50052
ENV RABBIT_URL=amqp://guest:guest@rabbitmq:5672/
ENV RABBIT_QUEUE=weather-tweets

EXPOSE 50052

CMD ["./rabbit-writer"]