#!/bin/bash

# Ejecutar localmente para enviar tráfico
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
INGRESS_PORT="80"

echo "Enviando peticiones de prueba al sistema..."
echo "Ingress IP: $INGRESS_IP"

# Enviar algunas peticiones de chinautla para probar
for i in {1..20}; do
  curl -X POST http://${INGRESS_IP}:${INGRESS_PORT}/tweet \
    -H "Content-Type: application/json" \
    -d '{"municipality": "chinautla", "temperature": 25, "humidity": 75, "weather": "sunny"}'
  echo ""
  sleep 1
done

for i in {1..15}; do
  curl -X POST http://${INGRESS_IP}:${INGRESS_PORT}/tweet \
    -H "Content-Type: application/json" \
    -d '{"municipality": "chinautla", "temperature": 20, "humidity": 85, "weather": "cloudy"}'
  echo ""
  sleep 1
done

for i in {1..10}; do
  curl -X POST http://${INGRESS_IP}:${INGRESS_PORT}/tweet \
    -H "Content-Type: application/json" \
    -d '{"municipality": "chinautla", "temperature": 18, "humidity": 90, "weather": "rainy"}'
  echo ""
  sleep 1
done

for i in {1..5}; do
  curl -X POST http://${INGRESS_IP}:${INGRESS_PORT}/tweet \
    -H "Content-Type: application/json" \
    -d '{"municipality": "chinautla", "temperature": 16, "humidity": 95, "weather": "foggy"}'
  echo ""
  sleep 1
done

echo "Peticiones de prueba enviadas. Verifica el dashboard de Grafana en http://${INGRESS_IP}/grafana"
echo "Usuario: admin, Contraseña: admin"