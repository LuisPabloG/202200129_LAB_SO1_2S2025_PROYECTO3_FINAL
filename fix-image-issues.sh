#!/bin/bash

# Script para corregir problemas de imágenes
echo "Corrigiendo problemas de imágenes en las configuraciones de Kubernetes..."

# Función para actualizar las imágenes en los archivos de configuración
update_image_in_file() {
  local file=$1
  local old_image=$2
  local new_image=$3
  
  echo "Actualizando imagen en $file: $old_image -> $new_image"
  sed -i "s|image: $old_image|image: $new_image|g" "$file"
}

# Actualizar imágenes en los archivos de configuración
update_image_in_file "./k8s/3-go-service-1.yaml" "34.31.7.251:5000/go-grpc-client:latest" "luispablog/go-grpc-client:latest"
update_image_in_file "./k8s/4-go-writer-services.yaml" "34.31.7.251:5000/go-kafka-writer:latest" "luispablog/go-kafka-writer:latest"
update_image_in_file "./k8s/4-go-writer-services.yaml" "34.31.7.251:5000/go-rabbitmq-writer:latest" "luispablog/go-rabbitmq-writer:latest"
update_image_in_file "./k8s/8-consumers.yaml" "34.31.7.251:5000/kafka-consumer:latest" "luispablog/kafka-consumer:latest"
update_image_in_file "./k8s/8-consumers.yaml" "34.31.7.251:5000/rabbitmq-consumer:latest" "luispablog/rabbitmq-consumer:latest"
update_image_in_file "./k8s/2-api-rust.yaml" "34.31.7.251:5000/rust-api:latest" "luispablog/rust-api:latest"

echo "Actualizaciones de imágenes completadas. Ahora puedes hacer commit de los cambios y ejecutar el despliegue."
