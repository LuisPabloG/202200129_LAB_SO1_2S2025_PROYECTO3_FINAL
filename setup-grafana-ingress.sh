#!/bin/bash

# Script para configurar el acceso a Grafana a través de Ingress

echo "Configurando acceso a Grafana a través de Ingress..."

# Obtener la IP del Ingress Controller
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$INGRESS_IP" ]; then
  echo "Error: No se encontró la IP externa del Ingress Controller."
  echo "Verificando si el servicio existe..."
  kubectl get svc -n ingress-nginx
  exit 1
fi

echo "IP del Ingress Controller: $INGRESS_IP"

# Crear o actualizar el Ingress para Grafana
echo "Creando regla de Ingress para Grafana..."
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: sopes3
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /\$2
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
spec:
  rules:
  - http:
      paths:
      - path: /grafana(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: grafana-service
            port:
              number: 3000
EOF

echo "Regla de Ingress creada."

# Verificar el estado del Ingress
kubectl get ingress -n sopes3

echo "======================================"
echo "Grafana debería estar accesible a través de:"
echo "http://${INGRESS_IP}/grafana"
echo "======================================"
echo "Si sigue sin funcionar, intenta con:"
echo "1. ./grafana-port-forward.sh (método que ya sabemos que funciona)"
echo "2. ./fix-grafana-external-access.sh (para intentar arreglar el acceso directo)"
echo "======================================"