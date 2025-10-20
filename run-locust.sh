#!/bin/bash

# Script para iniciar Locust con la configuración correcta
# Este script inicia Locust para generar tráfico de prueba

# Variables de configuración
INGRESS_IP="104.198.150.238"  # Reemplaza con la IP de tu Ingress
LOCUST_FILE="locustfile.py"

echo "=== Iniciando Locust para generar tráfico de prueba ==="
echo "IP del Ingress: $INGRESS_IP"

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

# Iniciar Locust
echo "✅ Iniciando Locust..."
echo "   Accede a la interfaz web en: http://localhost:8089"
echo "   Configura:"
echo "     - Número de usuarios: 10"
echo "     - Tasa de generación: 10 usuarios por segundo"
echo "     - Total de peticiones: 10,000"

locust -f "$LOCUST_FILE" --host="http://$INGRESS_IP"