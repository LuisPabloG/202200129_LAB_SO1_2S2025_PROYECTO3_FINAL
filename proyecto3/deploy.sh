#!/bin/bash

# Configurar NGINX Ingress Controller si no está instalado
echo "Verificando si NGINX Ingress Controller está instalado..."
if ! kubectl get namespace ingress-nginx &> /dev/null; then
  echo "Instalando NGINX Ingress Controller..."
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
  # Esperar a que se cree el controlador
  echo "Esperando a que se cree el controlador de Ingress..."
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=120s
else
  echo "NGINX Ingress Controller ya está instalado."
fi

# Aplicar configuraciones de Kubernetes en orden
echo "Aplicando configuraciones de Kubernetes..."
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/06-kafka.yaml
kubectl apply -f k8s/07-rabbitmq.yaml
kubectl apply -f k8s/10-valkey.yaml

# Esperar a que los servicios básicos estén listos
echo "Esperando a que los servicios básicos estén listos..."
sleep 30

# Aplicar el resto de las configuraciones
kubectl apply -f k8s/02-rust-api.yaml
kubectl apply -f k8s/03-go-api.yaml
kubectl apply -f k8s/04-kafka-writer.yaml
kubectl apply -f k8s/05-rabbit-writer.yaml
kubectl apply -f k8s/08-kafka-consumer.yaml
kubectl apply -f k8s/09-rabbit-consumer.yaml
kubectl apply -f k8s/11-locust.yaml
kubectl apply -f k8s/12-grafana.yaml

# Aplicar Ingress al final
kubectl apply -f k8s/01-ingress.yaml

echo "Verificando el estado de los pods..."
kubectl get pods -n proyecto3

echo "¡Configuración completada!"
echo "Puedes acceder a los servicios a través del Ingress."