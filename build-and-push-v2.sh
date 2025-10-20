#!/bin/bash

ZOT_IP="35.188.198.252"
ZOT_REGISTRY="${ZOT_IP}:5000"

echo "🚀 Building and pushing images to $ZOT_REGISTRY"

# Configurar Docker para usar registry inseguro
echo "🔧 Configuring Docker daemon..."
sudo tee /etc/docker/daemon.json << DOCKER_EOF
{
  "insecure-registries": ["${ZOT_REGISTRY}"],
  "features": {
    "buildkit": true
  }
}
DOCKER_EOF

sudo systemctl restart docker
sleep 5

# Función para build y push con manejo de errores
build_and_push() {
    local service=$1
    local dir=$2
    
    echo "📦 Building $service..."
    cd $dir
    
    if docker build --platform linux/amd64 -t ${ZOT_REGISTRY}/${service}:latest .; then
        echo "✅ Build successful for $service"
        
        if docker push ${ZOT_REGISTRY}/${service}:latest; then
            echo "✅ Push successful for $service"
        else
            echo "❌ Push failed for $service"
            return 1
        fi
    else
        echo "❌ Build failed for $service"
        return 1
    fi
    
    cd ..
}

# Rust API
build_and_push "rust-api" "rust-api"

# Go gRPC Client
build_and_push "go-grpc-client" "go-grpc-client"

# Go Kafka Writer
build_and_push "go-kafka-writer" "go-kafka-writer"

# Go RabbitMQ Writer
build_and_push "go-rabbitmq-writer" "go-rabbitmq-writer"

# Kafka Consumer
build_and_push "kafka-consumer" "go-kafka-consumer"

# RabbitMQ Consumer
build_and_push "rabbitmq-consumer" "go-rabbitmq-consumer"

echo ""
echo "✅ Build process completed!"
echo "🔍 Verify at: http://${ZOT_IP}:5000/v2/_catalog"
curl http://${ZOT_IP}:5000/v2/_catalog
