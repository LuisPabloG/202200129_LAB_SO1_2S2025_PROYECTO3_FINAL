#!/bin/bash

# Script para construir y desplegar el proxy de Valkey
# Este script facilita el despliegue del servicio proxy que expone datos de Valkey a Grafana

# Variables de configuración
ZOT_IP="$(gcloud compute instances list --format="get(networkInterfaces[0].accessConfigs[0].natIP)" --filter="name:zot-vm")"
IMAGE_NAME="valkey-proxy:latest"
ZOT_REGISTRY="$ZOT_IP:5000"
DEPLOYMENT_YAML="valkey-proxy-deployment.yaml"

echo "=== Construyendo y desplegando el proxy de Valkey ==="
echo "IP del Registry Zot: $ZOT_IP"

# Verificar que existen los archivos necesarios
if [ ! -f "valkey-proxy.py" ] || [ ! -f "Dockerfile.valkey-proxy" ] || [ ! -f "$DEPLOYMENT_YAML" ]; then
    echo "❌ Error: No se encontraron los archivos necesarios"
    echo "   Asegúrate de estar en el directorio correcto donde están los archivos del proyecto"
    exit 1
fi

# Actualizar la IP del registry en el archivo YAML
echo "🔄 Actualizando la IP del registry en el archivo YAML..."
sed -i "s/REGISTRY_IP/$ZOT_IP/g" $DEPLOYMENT_YAML

# Construir la imagen Docker
echo "🔄 Construyendo la imagen Docker..."
docker build -f Dockerfile.valkey-proxy -t $IMAGE_NAME .

# Etiquetar la imagen para el registry
echo "🔄 Etiquetando la imagen para el registry Zot..."
docker tag $IMAGE_NAME $ZOT_REGISTRY/$IMAGE_NAME

# Subir la imagen al registry
echo "🔄 Subiendo la imagen al registry Zot..."
docker push $ZOT_REGISTRY/$IMAGE_NAME

# Desplegar en Kubernetes
echo "🔄 Desplegando en Kubernetes..."
kubectl apply -f $DEPLOYMENT_YAML

# Esperar a que el pod esté listo
echo "⏳ Esperando a que el pod esté listo..."
kubectl wait --for=condition=ready pod -l app=valkey-proxy --timeout=120s

# Obtener la IP externa del servicio
echo "⏳ Esperando a que se asigne una IP externa al servicio..."
IP_EXTERNA=""
while [ -z "$IP_EXTERNA" ]; do
    IP_EXTERNA=$(kubectl get svc valkey-proxy-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    [ -z "$IP_EXTERNA" ] && sleep 5
done

echo "✅ ¡Despliegue completado!"
echo "📊 La API del proxy está disponible en: http://$IP_EXTERNA:3001"
echo ""
echo "Ahora puedes configurar el datasource SimpleJSON en Grafana:"
echo "1. Ve a Grafana → Configuración → Data sources"
echo "2. Añade un nuevo datasource SimpleJSON"
echo "3. URL: http://$IP_EXTERNA:3001"
echo "4. Guarda y comienza a crear tus paneles"