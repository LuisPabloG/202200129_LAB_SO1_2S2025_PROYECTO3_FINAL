#!/bin/bash

# Script para construir y subir las imágenes a Docker Hub
# Asegúrate de haber iniciado sesión con 'docker login' antes de ejecutar este script

echo "Construyendo y publicando imágenes en Docker Hub..."

# Función para construir y publicar una imagen
build_and_push() {
  local service_name=$1
  local service_path=$2
  
  echo "============================"
  echo "Procesando: $service_name"
  echo "============================"
  
  # Construir la imagen
  echo "Construyendo $service_name..."
  docker build -t "luispablog/$service_name:latest" "$service_path"
  
  # Publicar la imagen
  echo "Publicando $service_name a Docker Hub..."
  docker push "luispablog/$service_name:latest"
  
  echo "Imagen $service_name procesada correctamente."
  echo ""
}

# Iniciar sesión en Docker Hub (pedirá usuario y contraseña)
echo "Por favor, inicia sesión en Docker Hub:"
docker login

# Construir y publicar cada servicio
build_and_push "go-grpc-client" "./go-services/grpc-client"
build_and_push "go-kafka-writer" "./go-services/kafka-writer"
build_and_push "go-rabbitmq-writer" "./go-services/rabbitmq-writer"
build_and_push "kafka-consumer" "./go-services/kafka-consumer"
build_and_push "rabbitmq-consumer" "./go-services/rabbitmq-consumer"
build_and_push "rust-api" "./api-rust"

echo "¡Todas las imágenes han sido construidas y publicadas en Docker Hub!"
echo "Ahora puedes ejecutar el despliegue en Kubernetes."