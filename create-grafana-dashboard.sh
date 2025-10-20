#!/bin/bash

# Script para generar datos simulados y dashboards en Grafana
echo "Generando datos y dashboards para Grafana..."

# Obtener la IP externa del servicio de Grafana
GRAFANA_IP=$(kubectl get service grafana-service -n sopes3 -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
GRAFANA_PORT="3000"

# URL para la API de Grafana
GRAFANA_API="http://${GRAFANA_IP}:${GRAFANA_PORT}/api"

echo "Usando Grafana en: ${GRAFANA_API}"

# Crear fuente de datos simulada para TestData
echo "Creando fuente de datos de prueba..."
cat > testdata_source.json << EOL
{
  "name": "TestData",
  "type": "testdata",
  "access": "proxy",
  "isDefault": true
}
EOL

curl -X POST -H "Content-Type: application/json" -d @testdata_source.json ${GRAFANA_API}/datasources -u admin:admin

# Crear un panel de prueba con datos del clima de chinautla
echo "Creando dashboard del clima..."
cat > weather_dashboard.json << EOL
{
  "dashboard": {
    "id": null,
    "title": "Clima en Chinautla - 202200129",
    "tags": ["weather", "chinautla", "sopes3"],
    "timezone": "browser",
    "schemaVersion": 16,
    "version": 0,
    "refresh": "5s",
    "panels": [
      {
        "title": "Temperatura en Chinautla",
        "type": "graph",
        "gridPos": {
          "x": 0,
          "y": 0,
          "w": 12,
          "h": 8
        },
        "targets": [
          {
            "refId": "A",
            "scenarioId": "random_walk",
            "seriesCount": 1,
            "min": 15,
            "max": 35,
            "alias": "Temperatura (°C)"
          }
        ],
        "yaxes": [
          {
            "format": "celsius",
            "label": "Temperatura",
            "min": 15,
            "max": 35
          },
          {
            "format": "short",
            "label": "",
            "show": false
          }
        ]
      },
      {
        "title": "Humedad en Chinautla",
        "type": "graph",
        "gridPos": {
          "x": 12,
          "y": 0,
          "w": 12,
          "h": 8
        },
        "targets": [
          {
            "refId": "B",
            "scenarioId": "random_walk",
            "seriesCount": 1,
            "min": 50,
            "max": 100,
            "alias": "Humedad (%)"
          }
        ],
        "yaxes": [
          {
            "format": "percent",
            "label": "Humedad",
            "min": 40,
            "max": 100
          },
          {
            "format": "short",
            "label": "",
            "show": false
          }
        ]
      },
      {
        "title": "Condiciones Climáticas",
        "type": "stat",
        "gridPos": {
          "x": 0,
          "y": 8,
          "w": 6,
          "h": 6
        },
        "targets": [
          {
            "refId": "A",
            "scenarioId": "random_walk",
            "min": 5,
            "max": 25,
            "alias": "Soleado"
          }
        ],
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "justifyMode": "auto",
          "textMode": "auto"
        }
      },
      {
        "title": "Condiciones Climáticas",
        "type": "stat",
        "gridPos": {
          "x": 6,
          "y": 8,
          "w": 6,
          "h": 6
        },
        "targets": [
          {
            "refId": "A",
            "scenarioId": "random_walk",
            "min": 0,
            "max": 15,
            "alias": "Nublado"
          }
        ],
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "justifyMode": "auto",
          "textMode": "auto"
        }
      },
      {
        "title": "Condiciones Climáticas",
        "type": "stat",
        "gridPos": {
          "x": 12,
          "y": 8,
          "w": 6,
          "h": 6
        },
        "targets": [
          {
            "refId": "A",
            "scenarioId": "random_walk",
            "min": 0,
            "max": 10,
            "alias": "Lluvioso"
          }
        ],
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "justifyMode": "auto",
          "textMode": "auto"
        }
      },
      {
        "title": "Condiciones Climáticas",
        "type": "stat",
        "gridPos": {
          "x": 18,
          "y": 8,
          "w": 6,
          "h": 6
        },
        "targets": [
          {
            "refId": "A",
            "scenarioId": "random_walk",
            "min": 0,
            "max": 5,
            "alias": "Niebla"
          }
        ],
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "justifyMode": "auto",
          "textMode": "auto"
        }
      },
      {
        "title": "Información de Proyecto - 202200129",
        "type": "text",
        "gridPos": {
          "x": 0,
          "y": 14,
          "w": 24,
          "h": 3
        },
        "options": {
          "mode": "markdown",
          "content": "# Proyecto 3 - Sistemas Operativos 1\n## Carnet: 202200129\n### Municipio asignado: Chinautla"
        }
      }
    ]
  },
  "folderId": 0,
  "overwrite": false
}
EOL

echo "Publicando dashboard..."
curl -X POST -H "Content-Type: application/json" -d @weather_dashboard.json ${GRAFANA_API}/dashboards/db -u admin:admin

echo ""
echo "==================================="
echo "Dashboard creado exitosamente"
echo "Accede a Grafana en: http://${GRAFANA_IP}:${GRAFANA_PORT}"
echo "Usuario: admin"
echo "Contraseña: admin"
echo "==================================="

# Simular envío de datos al API
echo "Enviando datos de prueba al API..."

# Obtener la IP del servicio de API o ingress
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$INGRESS_IP" ]; then
  echo "No se encontró la IP del Ingress. Usando la IP del servicio API directamente..."
  API_IP=$(kubectl get svc -n sopes3 api-server-service -o jsonpath='{.spec.clusterIP}')
  API_PORT="80"
  API_URL="http://${API_IP}:${API_PORT}/tweet"
  echo "API URL interno: ${API_URL} (solo accesible dentro del cluster)"
else
  API_URL="http://${INGRESS_IP}/tweet"
  echo "API URL externo: ${API_URL}"
  
  # Enviar algunas peticiones de prueba
  for i in {1..5}; do
    echo "Enviando petición $i al API..."
    curl -X POST "$API_URL" \
      -H "Content-Type: application/json" \
      -d '{"municipality": "chinautla", "temperature": 25, "humidity": 75, "weather": "sunny"}'
    echo ""
    sleep 1
  done
fi

echo "Proceso completado."