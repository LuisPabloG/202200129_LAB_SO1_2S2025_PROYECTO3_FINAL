#!/bin/bash

# Script para solucionar problemas de despliegue
echo "Script de resolución de problemas para Kubernetes..."

# Eliminar los pods con problemas para que se recreen
echo "Eliminando pods con problemas para que se recreen..."

# Función para reiniciar un deployment
restart_deployment() {
  local deployment=$1
  local namespace=${2:-sopes3}
  
  echo "Reiniciando deployment $deployment en namespace $namespace"
  kubectl rollout restart deployment $deployment -n $namespace
  echo "Deployment $deployment reiniciado."
}

# Reiniciar los deployments principales
restart_deployment "go-grpc-client" 
restart_deployment "go-service-1"
restart_deployment "go-service-kafka-writer"
restart_deployment "go-service-rabbit-writer"
restart_deployment "kafka-consumer"
restart_deployment "rabbit-consumer"
restart_deployment "api-rust"
restart_deployment "kafka"
restart_deployment "rabbitmq"
restart_deployment "valkey"
restart_deployment "zookeeper"
restart_deployment "nginx-ingress-controller" "ingress-nginx"

echo "Esperando a que los pods se reinicien..."
sleep 30

# Verificar el estado
kubectl get pods -n sopes3
kubectl get pods -n ingress-nginx

echo "Si algunos pods siguen con problemas, puedes verificar los eventos específicos con:"
echo "kubectl describe pod <nombre-pod> -n <namespace>"
echo ""
echo "Para verificar logs:"
echo "kubectl logs <nombre-pod> -n <namespace>"