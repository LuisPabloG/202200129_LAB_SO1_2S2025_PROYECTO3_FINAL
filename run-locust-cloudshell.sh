#!/bin/bash

# Script para ejecutar Locust con Python directamente en Cloud Shell
# Este script evita problemas de PATH con el comando locust

# Variables de configuración
INGRESS_IP="104.198.150.238"  # IP del Ingress para acceder a la API
LOCUST_FILE="locustfile.py"
PORT=8089
WEB_HOST="0.0.0.0"  # Importante para Cloud Shell

echo "=== Iniciando Locust para generar tráfico de prueba ==="
echo "IP del Ingress: $INGRESS_IP"

# Verificar que el archivo locustfile.py existe
if [ ! -f "$LOCUST_FILE" ]; then
    echo "❌ Error: No se encontró el archivo $LOCUST_FILE"
    echo "   Asegúrate de estar en el directorio correcto o crea el archivo según la guía."
    exit 1
fi

# Instalar Locust con pip si es necesario
echo "🔄 Asegurando que Locust está instalado..."
python3 -m pip install --user locust

echo "✅ Configurando Locust para Cloud Shell..."
echo ""
echo "Para acceder a la interfaz web de Locust en Cloud Shell:"
echo "1. Espera a que inicie Locust (verás mensajes de 'Starting Locust')"
echo "2. Haz clic en el botón 'Web Preview' en la parte superior derecha"
echo "3. Selecciona 'Change port' y escribe 8089"
echo ""
echo "O accede directamente a esta URL cuando veas que Locust ha iniciado:"
echo "https://ssh.cloud.google.com/devshell/proxy?port=8089&scope=serverless"
echo ""
echo "Configuración para la simulación:"
echo "  - Número de usuarios: 10"
echo "  - Tasa de generación: 10 usuarios por segundo"
echo "  - Total de peticiones: 10,000"
echo ""
echo "🚀 Iniciando Locust con Python..."

# Ejecutar Locust con el módulo de Python directamente (evita problemas de PATH)
python3 -m locust -f "$LOCUST_FILE" --host="http://$INGRESS_IP" --web-host="$WEB_HOST" --web-port="$PORT"