#!/bin/bash
set -e

# Configuración de variables
ZOT_REGISTRY="34.31.7.251:5000"
PROJECT_DIR=$(pwd)
ERROR_COUNT=0
SUCCESS_COUNT=0
FAILED_COMPONENTS=()

echo "=== Comenzando la construcción y publicación de imágenes en $ZOT_REGISTRY ==="
echo "Directorio del proyecto: $PROJECT_DIR"

# Verificar si Docker está disponible
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker no está instalado o no está disponible en el PATH"
    exit 1
fi

# Primero, ejecutamos el script para inicializar los módulos Go
if [ -f ./init_go_modules.sh ]; then
  echo "Inicializando módulos Go..."
  chmod +x ./init_go_modules.sh
  ./init_go_modules.sh
else
  echo "ERROR: El archivo init_go_modules.sh no existe"
  exit 1
fi

# Función para construir y publicar una imagen
build_and_push() {
  local component=$1
  local tag=$2
  local directory=$3
  local retry_count=${4:-3}  # Número de intentos, por defecto 3
  local build_success=false

  echo "==================================================================="
  echo "=== Construyendo $component ($directory) ==="
  echo "==================================================================="
  
  # Verificar que el directorio existe
  if [ ! -d "$directory" ]; then
    echo "ERROR: El directorio $directory no existe"
    FAILED_COMPONENTS+=("$component (directorio no existe)")
    ERROR_COUNT=$((ERROR_COUNT + 1))
    return 1
  fi
  
  # Cambiar al directorio del componente
  cd "$directory" || {
    echo "ERROR: No se pudo acceder al directorio $directory"
    FAILED_COMPONENTS+=("$component (no se pudo acceder al directorio)")
    ERROR_COUNT=$((ERROR_COUNT + 1))
    return 1
  }
  
  # Construir la imagen
  echo "Ejecutando: docker build -t ${component}:${tag} ."
  if docker build -t "${component}:${tag}" .; then
    build_success=true
    echo "✅ Construcción de $component completada exitosamente"
  else
    echo "❌ ERROR: La construcción de $component falló"
    FAILED_COMPONENTS+=("$component (falló construcción)")
    ERROR_COUNT=$((ERROR_COUNT + 1))
    cd "$PROJECT_DIR"
    return 1
  fi
  
  # Etiquetar la imagen para el registro
  echo "Etiquetando: docker tag ${component}:${tag} ${ZOT_REGISTRY}/${component}:${tag}"
  docker tag "${component}:${tag}" "${ZOT_REGISTRY}/${component}:${tag}"
  
  # Publicar la imagen en el registro
  echo "=== Publicando $component en Zot ==="
  local push_success=false
  
  # Intentar push hasta el número de intentos especificado
  for i in $(seq 1 $retry_count); do
    echo "Intento $i de $retry_count..."
    if docker push "${ZOT_REGISTRY}/${component}:${tag}"; then
      push_success=true
      echo "✅ Publicación de $component completada exitosamente"
      break
    else
      echo "❌ Intento $i falló, reintentando..."
      sleep 5
    fi
  done
  
  # Verificar si la publicación fue exitosa
  if [ "$push_success" = false ]; then
    echo "❌ ERROR: Todos los intentos de publicar $component fallaron"
    FAILED_COMPONENTS+=("$component (falló publicación)")
    ERROR_COUNT=$((ERROR_COUNT + 1))
  else
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  fi
  
  # Volver al directorio del proyecto
  cd "$PROJECT_DIR"
}

# Lista de componentes a construir
COMPONENTS=(
  "rust-api|latest|$PROJECT_DIR/rust-api"
  "go-api|latest|$PROJECT_DIR/go-api"
  "kafka-writer|latest|$PROJECT_DIR/go-writers/kafka"
  "rabbit-writer|latest|$PROJECT_DIR/go-writers/rabbit"
  "kafka-consumer|latest|$PROJECT_DIR/go-consumers/kafka"
  "rabbit-consumer|latest|$PROJECT_DIR/go-consumers/rabbit"
  "locust|latest|$PROJECT_DIR/locust"
)

# Construir y publicar cada componente
for component_info in "${COMPONENTS[@]}"; do
  IFS='|' read -r name tag directory <<< "$component_info"
  build_and_push "$name" "$tag" "$directory"
done

# Resumen del proceso
echo "==================================================================="
echo "=== RESUMEN DEL PROCESO ==="
echo "==================================================================="
echo "✅ Componentes construidos exitosamente: $SUCCESS_COUNT"
echo "❌ Componentes con errores: $ERROR_COUNT"

if [ ${#FAILED_COMPONENTS[@]} -gt 0 ]; then
  echo "Lista de componentes con errores:"
  for failed in "${FAILED_COMPONENTS[@]}"; do
    echo "  - $failed"
  done
  echo "Revisa los mensajes de error anteriores para más detalles."
  echo "Proceso completado con errores."
  exit 1
else
  echo "¡Proceso completado con éxito! Todas las imágenes fueron construidas y publicadas."
fi