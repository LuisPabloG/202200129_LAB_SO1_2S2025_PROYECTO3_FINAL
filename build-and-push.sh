#!/bin/bash

ZOT_IP="35.188.198.252"
ZOT_REGISTRY="${ZOT_IP}:5000"

echo "🚀 Building and pushing images to $ZOT_REGISTRY"

# Configurar Docker para usar registry inseguro
echo "🔧 Configuring Docker daemon..."
sudo tee /etc/docker/daemon.json << DOCKER_EOF
{
  "insecure-registries": ["${ZOT_REGISTRY}"]
}
DOCKER_EOF

sudo systemctl restart docker
sleep 5

# Rust API
echo "📦 Building Rust API..."
cd rust-api
docker build -t ${ZOT_REGISTRY}/rust-api:latest .
docker push ${ZOT_REGISTRY}/rust-api:latest
cd ..

# Go gRPC Client
echo "📦 Building Go gRPC Client..."
cd go-grpc-client
docker build -t ${ZOT_REGISTRY}/go-grpc-client:latest .
docker push ${ZOT_REGISTRY}/go-grpc-client:latest
cd ..

# Go Kafka Writer
echo "📦 Building Go Kafka Writer..."
cd go-kafka-writer
docker build -t ${ZOT_REGISTRY}/go-kafka-writer:latest .
docker push ${ZOT_REGISTRY}/go-kafka-writer:latest
cd ..

# Go RabbitMQ Writer
echo "📦 Building Go RabbitMQ Writer..."
cd go-rabbitmq-writer
docker build -t ${ZOT_REGISTRY}/go-rabbitmq-writer:latest .
docker push ${ZOT_REGISTRY}/go-rabbitmq-writer:latest
cd ..

# Kafka Consumer
echo "📦 Building Kafka Consumer..."
cd go-kafka-consumer
docker build -t ${ZOT_REGISTRY}/kafka-consumer:latest .
docker push ${ZOT_REGISTRY}/kafka-consumer:latest
cd ..

# RabbitMQ Consumer
echo "📦 Building RabbitMQ Consumer..."
cd go-rabbitmq-consumer
docker build -t ${ZOT_REGISTRY}/rabbitmq-consumer:latest .
docker push ${ZOT_REGISTRY}/rabbitmq-consumer:latest
cd ..

echo "✅ All images built and pushed successfully!"
echo "🔍 Verify at: http://${ZOT_IP}:5000/v2/_catalog"
curl http://${ZOT_IP}:5000/v2/_catalog
