#!/bin/bash

# Script para ejecutar Locust con un archivo de configuración
# que envía un número específico de peticiones sin usar la interfaz web

# Variables de configuración
INGRESS_IP="104.198.150.238"  # Reemplaza con la IP de tu Ingress
LOCUST_FILE="locustfile.py"
NUM_USERS=10                  # Número de usuarios simultáneos
RUN_TIME="10m"                # Tiempo de ejecución
SPAWN_RATE=10                 # Tasa de generación de usuarios
NUM_REQUESTS=10000            # Número aproximado de solicitudes a enviar

echo "=== Iniciando simulación automática de Locust ==="
echo "IP del Ingress: $INGRESS_IP"
echo "Usuarios: $NUM_USERS"
echo "Tasa de generación: $SPAWN_RATE usuarios por segundo"
echo "Tiempo de ejecución: $RUN_TIME"
echo "Solicitudes objetivo: $NUM_REQUESTS"

# Verificar que el archivo locustfile.py existe
if [ ! -f "$LOCUST_FILE" ]; then
    echo "❌ Error: No se encontró el archivo $LOCUST_FILE"
    echo "   Asegúrate de estar en el directorio correcto o crea el archivo según la guía."
    exit 1
fi

# Verificar si Locust está instalado
if ! command -v locust &> /dev/null; then
    echo "⚠️ Locust no está instalado. Instalando..."
    pip install locust
fi

echo "✅ Iniciando simulación..."

# Ejecutar Locust en modo headless (sin interfaz web)
locust -f "$LOCUST_FILE" \
    --host="http://$INGRESS_IP" \
    --headless \
    --users=$NUM_USERS \
    --spawn-rate=$SPAWN_RATE \
    --run-time=$RUN_TIME \
    --csv=locust_results

echo "✅ Simulación completada"
echo "Los resultados se han guardado en archivos CSV con prefijo 'locust_results'"
echo "Para ver estadísticas básicas:"
echo "cat locust_results_stats.csv"