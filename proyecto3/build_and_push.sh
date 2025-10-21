#!/bin/bash

# Configuración de variables
ZOT_REGISTRY="34.31.7.251:5000"
PROJECT_DIR=$(pwd)

echo "Comenzando la construcción y publicación de imágenes en $ZOT_REGISTRY..."

# Función para construir y publicar una imagen
build_and_push() {
  local component=$1
  local tag=$2
  local directory=$3

  echo "=== Construyendo $component ==="
  cd $directory || exit 1
  docker build -t ${component}:${tag} .
  docker tag ${component}:${tag} ${ZOT_REGISTRY}/${component}:${tag}
  echo "=== Publicando $component en Zot ==="
  docker push ${ZOT_REGISTRY}/${component}:${tag}
  cd $PROJECT_DIR
}

# Crear directorios proto para cada componente Go
mkdir -p go-api/proto
mkdir -p go-writers/kafka/proto
mkdir -p go-writers/rabbit/proto

# Copiar archivo proto a cada componente
cp proto/weathertweet.proto go-api/proto/
cp proto/weathertweet.proto go-writers/kafka/proto/
cp proto/weathertweet.proto go-writers/rabbit/proto/

# Generar código Go desde proto para cada componente
echo "=== Generando código desde proto ==="
cd go-api
protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative proto/weathertweet.proto
cd $PROJECT_DIR

cd go-writers/kafka
protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative proto/weathertweet.proto
cd $PROJECT_DIR

cd go-writers/rabbit
protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative proto/weathertweet.proto
cd $PROJECT_DIR

# Construir y publicar las imágenes
build_and_push "rust-api" "latest" "$PROJECT_DIR/rust-api"
build_and_push "go-api" "latest" "$PROJECT_DIR/go-api"
build_and_push "kafka-writer" "latest" "$PROJECT_DIR/go-writers/kafka"
build_and_push "rabbit-writer" "latest" "$PROJECT_DIR/go-writers/rabbit"
build_and_push "kafka-consumer" "latest" "$PROJECT_DIR/go-consumers/kafka"
build_and_push "rabbit-consumer" "latest" "$PROJECT_DIR/go-consumers/rabbit"
build_and_push "locust" "latest" "$PROJECT_DIR/locust"

echo "¡Proceso completado con éxito!"