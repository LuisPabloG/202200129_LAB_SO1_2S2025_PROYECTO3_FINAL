#!/bin/bash

# Script para acceder rápidamente a Grafana
echo "Accediendo a Grafana..."

# Obtener la IP externa del servicio de Grafana
GRAFANA_IP=$(kubectl get service grafana-service -n sopes3 -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
GRAFANA_PORT="3000"

echo "==================================="
echo "Acceso a Grafana:"
echo "http://${GRAFANA_IP}:${GRAFANA_PORT}"
echo "Usuario: admin"
echo "Contraseña: admin"
echo "==================================="

# También mostrar la IP del Ingress
INGRESS_IP=$(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Alternativamente, puedes acceder a través del Ingress:"
echo "http://${INGRESS_IP}/grafana"
echo "==================================="

echo "Ejecutando pruebas para generar datos..."
echo "Si quieres generar datos de prueba, ejecuta:"
echo "./test-system.sh"