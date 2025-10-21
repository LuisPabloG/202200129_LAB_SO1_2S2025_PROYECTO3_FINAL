#!/bin/bash

# Este script da permisos de ejecución a todos los scripts .sh
chmod +x build_and_push.sh
chmod +x deploy.sh

# Crear un commit con todos los cambios
git add .
git commit -m "Implementación completa del Proyecto 3 - Tweets del Clima"

echo "¡Cambios comprometidos localmente!"
echo ""
echo "INSTRUCCIONES PARA DESPLEGAR EL PROYECTO:"
echo "==========================================="
echo ""
echo "1. Haz un push al repositorio remoto:"
echo "   git push origin main"
echo ""
echo "2. En Cloud Shell, clona el repositorio:"
echo "   git clone https://github.com/LuisPabloG/202200129_LAB_SO1_2S2025_PROYECTO3_FINAL.git"
echo "   cd 202200129_LAB_SO1_2S2025_PROYECTO3_FINAL/proyecto3"
echo ""
echo "3. Instala protoc y los plugins necesarios:"
echo "   apt-get update && apt-get install -y protobuf-compiler"
echo "   go install google.golang.org/protobuf/cmd/protoc-gen-go@latest"
echo "   go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest"
echo ""
echo "4. Ejecuta los scripts de despliegue:"
echo "   ./build_and_push.sh"
echo "   ./deploy.sh"
echo ""
echo "5. Verifica el despliegue:"
echo "   kubectl get pods -n proyecto3"
echo ""
echo "6. Configura Grafana:"
echo "   - Accede a Grafana a través del Ingress"
echo "   - Añade una fuente de datos de tipo Redis apuntando a valkey-service:6379"
echo "   - Importa el dashboard desde grafana-dashboard.json"
echo ""
echo "NOTA: Asegúrate de que tu Registry Zot esté configurado correctamente en la VM 34.31.7.251:5000"