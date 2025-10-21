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
RUN CGO_ENABLED=0 GOOS=linux go build -a -o go-api .

FROM alpine:latest  

WORKDIR /root/

COPY --from=builder /app/go-api .

ENV PORT=8080
ENV KAFKA_WRITER_ADDR=kafka-writer-service:50051
ENV RABBIT_WRITER_ADDR=rabbit-writer-service:50052

EXPOSE 8080

CMD ["./go-api"]