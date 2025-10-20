#!/bin/bash

# Script para iniciar Locust con la configuración correcta
# Este script inicia Locust para generar tráfico de prueba

# Variables de configuración
INGRESS_IP="104.198.150.238"  # Reemplaza con la IP de tu Ingress
LOCUST_FILE="locustfile.py"
PORT="8089"
WEB_HOST="0.0.0.0"  # Importante para Cloud Shell

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

# Detectar si estamos en Cloud Shell
IS_CLOUDSHELL=false
if [ -n "$CLOUD_SHELL" ] || [ -f /google/devshell/bashrc.google ]; then
    IS_CLOUDSHELL=true
fi

# Configuración específica para Cloud Shell
if [ "$IS_CLOUDSHELL" = true ]; then
    echo "✅ Detectado entorno Cloud Shell"
    echo ""
    echo "Para acceder a la interfaz web de Locust en Cloud Shell:"
    echo "1. Haz clic en el botón 'Web Preview' en la parte superior derecha"
    echo "2. Selecciona 'Preview on port 8089' o 'Change port' y pon 8089"
    echo ""
    echo "O accede directamente a esta URL:"
    echo "https://ssh.cloud.google.com/devshell/proxy?port=8089&scope=serverless"
    echo ""
else
    echo "✅ Iniciando Locust en entorno local..."
    echo "   Accede a la interfaz web en: http://localhost:$PORT"
fi

echo "   Configura:"
echo "     - Número de usuarios: 10"
echo "     - Tasa de generación: 10 usuarios por segundo"
echo "     - Total de peticiones: 10,000"

# Iniciar Locust con parámetros para permitir acceso externo
locust -f "$LOCUST_FILE" --host="http://$INGRESS_IP" --web-host="$WEB_HOST" --web-port="$PORT"