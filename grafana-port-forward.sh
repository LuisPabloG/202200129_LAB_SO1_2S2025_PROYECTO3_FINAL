#!/bin/bash

# Script para acceder a Grafana mediante port-forwarding
# Esta es una solución que no requiere autenticación ni LoadBalancer

echo "Accediendo a Grafana mediante port-forwarding..."

# Obtener el nombre del pod de Grafana
GRAFANA_POD=$(kubectl get pods -n sopes3 | grep grafana | head -n 1 | awk '{print $1}')

if [ -z "$GRAFANA_POD" ]; then
  echo "No se encontró ningún pod de Grafana. Asegúrate de que esté desplegado."
  exit 1
fi

echo "Encontrado pod de Grafana: $GRAFANA_POD"
echo "Estableciendo port-forwarding del pod de Grafana al puerto 8080 local..."
echo "Una vez iniciado, puedes acceder a Grafana en: http://localhost:8080"
echo "IMPORTANTE: Mantén esta terminal abierta mientras usas Grafana."
echo "Presiona Ctrl+C para detener el port-forwarding cuando termines."
echo "========================================================"

# Establecer port-forwarding
kubectl port-forward -n sopes3 $GRAFANA_POD 8080:3000