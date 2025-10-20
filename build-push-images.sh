#!/bin/bash

# Configuración
ZOT_REGISTRY="34.31.7.251:5000"

# Compilar y subir imágenes
echo "Construyendo y subiendo imágenes al registro Zot..."

# API Rust
echo "Construyendo API Rust..."
cd /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/api-rust
docker build -t api-rust .
docker tag api-rust ${ZOT_REGISTRY}/api-rust:latest
docker push ${ZOT_REGISTRY}/api-rust:latest

# Go Service 1 (gRPC Client)
# Omitido por ahora hasta que se creen los archivos correctamente
echo "Saltando Go Service 1..."

# Kafka Writer
# Omitido por ahora hasta que se creen los archivos correctamente
echo "Saltando Kafka Writer..."

# RabbitMQ Writer
# Omitido por ahora hasta que se creen los archivos correctamente
echo "Saltando RabbitMQ Writer..."

# Kafka Consumer
# Omitido por ahora hasta que se creen los archivos correctamente
echo "Saltando Kafka Consumer..."

# RabbitMQ Consumer
# Omitido por ahora hasta que se creen los archivos correctamente
echo "Saltando RabbitMQ Consumer..."

# Locust
echo "Construyendo Locust..."
cd /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/locust
docker build -t locust .
docker tag locust ${ZOT_REGISTRY}/locust:latest
docker push ${ZOT_REGISTRY}/locust:latest

echo "Todas las imágenes han sido construidas y subidas al registro Zot."