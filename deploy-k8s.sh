#!/bin/bash

# Aplicar los archivos de configuración de Kubernetes
echo "Aplicando configuraciones de Kubernetes..."

# Crear namespaces
kubectl apply -f /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s/0-namespaces.yaml
echo "Namespaces creados."

# Instalar Ingress NGINX
kubectl apply -f /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s/1-nginx-ingress.yaml
echo "Ingress NGINX instalado."

# Desplegar Kafka
kubectl apply -f /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s/5-kafka.yaml
echo "Kafka desplegado."

# Desplegar RabbitMQ
kubectl apply -f /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s/6-rabbitmq.yaml
echo "RabbitMQ desplegado."

# Desplegar Valkey
kubectl apply -f /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s/7-valkey.yaml
echo "Valkey desplegado."

# Desplegar servicios Go (Writers)
kubectl apply -f /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s/4-go-writer-services.yaml
echo "Servicios Go (Writers) desplegados."

# Desplegar servicio Go (gRPC Client)
kubectl apply -f /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s/3-go-service-1.yaml
echo "Servicio Go (gRPC Client) desplegado."

# Desplegar API Rust
kubectl apply -f /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s/2-api-rust.yaml
echo "API Rust desplegada."

# Desplegar consumidores
kubectl apply -f /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s/8-consumers.yaml
echo "Consumidores desplegados."

# Desplegar Grafana
kubectl apply -f /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s/9.1-grafana-datasource.yaml
kubectl apply -f /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s/9.2-grafana-dashboard.yaml
kubectl apply -f /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s/9-grafana.yaml
echo "Grafana desplegado con dashboards."

# Desplegar Ingress
kubectl apply -f /home/luis-pablo-garcia/Escritorio/PROYECTO3-SOPES/k8s/10-ingress.yaml
echo "Ingress configurado."

echo "Esperando a que todos los pods estén disponibles..."
sleep 30

# Verificar el estado de los pods
kubectl get pods -n sopes3
kubectl get pods -n monitoring
kubectl get pods -n ingress-nginx

# Obtener la IP externa del Ingress Controller
echo "Obteniendo IP externa del Ingress Controller..."
kubectl get service ingress-nginx -n ingress-nginx

echo "Configuración completa. Ahora puedes acceder a tu aplicación a través de la IP externa del Ingress Controller."
echo "Para ver el dashboard de Grafana, visita http://<EXTERNAL-IP>/grafana"
echo "Usuario: admin, Contraseña: admin"