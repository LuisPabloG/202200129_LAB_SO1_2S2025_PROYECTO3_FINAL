#!/bin/bash

# Ruta al directorio de kubernetes
K8S_DIR="/home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s"

# Usar una imagen de Docker con kubectl y autenticación gcloud ya configurada
echo "Aplicando configuraciones de Kubernetes usando Docker..."

# Ejecutar comandos en un contenedor que tiene kubectl y gcloud instalados
docker run --rm -v "$K8S_DIR:/k8s" -v "$HOME/.kube:/root/.kube" -v "$HOME/.config/gcloud:/root/.config/gcloud" google/cloud-sdk:latest bash -c "
echo 'Aplicando namespaces...'
kubectl apply -f /k8s/0-namespaces.yaml

echo 'Instalando Ingress NGINX...'
kubectl apply -f /k8s/1-nginx-ingress.yaml

echo 'Desplegando Kafka...'
kubectl apply -f /k8s/5-kafka.yaml

echo 'Desplegando RabbitMQ...'
kubectl apply -f /k8s/6-rabbitmq.yaml

echo 'Desplegando Valkey...'
kubectl apply -f /k8s/7-valkey.yaml

echo 'Desplegando servicios Go (Writers)...'
kubectl apply -f /k8s/4-go-writer-services.yaml

echo 'Desplegando servicio Go (gRPC Client)...'
kubectl apply -f /k8s/3-go-service-1.yaml

echo 'Desplegando API Rust...'
kubectl apply -f /k8s/2-api-rust.yaml

echo 'Desplegando consumidores...'
kubectl apply -f /k8s/8-consumers.yaml

echo 'Desplegando Grafana...'
kubectl apply -f /k8s/9.1-grafana-datasource.yaml
kubectl apply -f /k8s/9.2-grafana-dashboard.yaml
kubectl apply -f /k8s/9-grafana.yaml

echo 'Configurando Ingress...'
kubectl apply -f /k8s/10-ingress.yaml

echo 'Verificando el estado de los pods...'
kubectl get pods -n sopes3
kubectl get pods -n monitoring
kubectl get pods -n ingress-nginx

echo 'Obteniendo IP externa del Ingress Controller...'
kubectl get service ingress-nginx-controller -n ingress-nginx
"

echo "Configuración completa. Ahora puedes acceder a tu aplicación a través de la IP externa del Ingress Controller."
echo "Para ver el dashboard de Grafana, visita http://<EXTERNAL-IP>/grafana"
echo "Usuario: admin, Contraseña: admin"
