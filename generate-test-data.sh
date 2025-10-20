#!/bin/bash

# Script para generar simulación de datos para el dashboard
# Este script envía datos simulados al API para mostrar en el dashboard

echo "Generando datos simulados del clima para Chinautla..."

# Obtener la IP del ingress
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$INGRESS_IP" ]; then
  echo "No se pudo obtener la IP del ingress. Verificando IP del servicio API..."
  API_IP=$(kubectl get svc -n sopes3 api-server-service -o jsonpath='{.spec.clusterIP}')
  if [ -z "$API_IP" ]; then
    echo "No se encontró ninguna API disponible. Verifica que los servicios estén funcionando."
    exit 1
  fi
  echo "Usando IP interna del API: $API_IP (esto solo funcionará dentro del cluster)"
  URL="http://${API_IP}/tweet"
else
  echo "Usando Ingress IP: $INGRESS_IP"
  URL="http://${INGRESS_IP}/tweet"
fi

# Función para generar valores aleatorios
random_temp() {
  echo $((RANDOM % 10 + 20)) # Temperatura entre 20-30°C
}

random_humidity() {
  echo $((RANDOM % 30 + 60)) # Humedad entre 60-90%
}

random_weather() {
  weather=("sunny" "cloudy" "rainy" "foggy")
  echo ${weather[$((RANDOM % 4))]}
}

# Enviar datos simulados en bucle
echo "Enviando datos al API cada 5 segundos. Presiona Ctrl+C para detener."
echo "URL del API: $URL"
echo "================================================"

count=1
while true; do
  temp=$(random_temp)
  humidity=$(random_humidity)
  weather=$(random_weather)
  
  echo "Enviando dato #$count: Temperatura: $temp°C, Humedad: $humidity%, Clima: $weather"
  
  curl -X POST $URL \
    -H "Content-Type: application/json" \
    -d "{\"municipality\": \"chinautla\", \"temperature\": $temp, \"humidity\": $humidity, \"weather\": \"$weather\"}"
  
  echo ""
  count=$((count + 1))
  sleep 5
done