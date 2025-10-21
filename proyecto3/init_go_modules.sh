#!/bin/bash
set -e

echo "===== Preparando módulos Go ====="

# Generar proto y luego inicializar módulos de Go
# Para cada uno, vamos a inicializar el módulo, obtener dependencias y generar go.sum

# Directorio raíz del proyecto
PROJECT_DIR=$(pwd)

echo "Directorio del proyecto: $PROJECT_DIR"

# Crear directorios proto para cada componente Go
echo "Creando directorios proto..."
mkdir -p go-api/proto
mkdir -p go-writers/kafka/proto
mkdir -p go-writers/rabbit/proto
mkdir -p go-consumers/kafka/proto
mkdir -p go-consumers/rabbit/proto

# Copiar archivo proto a cada componente
echo "Copiando archivo proto a los componentes..."
cp proto/weathertweet.proto go-api/proto/
cp proto/weathertweet.proto go-writers/kafka/proto/
cp proto/weathertweet.proto go-writers/rabbit/proto/
cp proto/weathertweet.proto go-consumers/kafka/proto/
cp proto/weathertweet.proto go-consumers/rabbit/proto/

# Instalar protoc-gen-go y protoc-gen-go-grpc si no están ya instalados
echo "Verificando herramientas de protobuf..."
if ! command -v protoc-gen-go &> /dev/null; then
    echo "Instalando protoc-gen-go..."
    go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28.1
fi

if ! command -v protoc-gen-go-grpc &> /dev/null; then
    echo "Instalando protoc-gen-go-grpc..."
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2.0
fi

# Asegurarnos que los binarios están en el PATH
export PATH="$PATH:$(go env GOPATH)/bin"
echo "PATH actualizado: $PATH"

# Función para inicializar un módulo Go con dependencias explícitas
init_go_module() {
    local directory=$1
    local module_name=$2
    shift 2
    local dependencies=("$@")
    
    echo "===== Inicializando módulo en $directory como $module_name ====="
    cd "$directory" || { echo "No se pudo acceder al directorio $directory"; exit 1; }
    
    # Asegurarnos de que sea un módulo Go
    if [ ! -f go.mod ]; then
        echo "Creando nuevo módulo Go: $module_name"
        go mod init "$module_name"
    else
        echo "El módulo ya existe, actualizando..."
    fi
    
    # Instalar dependencias explícitamente
    for dep in "${dependencies[@]}"; do
        echo "Instalando dependencia: $dep"
        go get -v "$dep"
    done
    
    # Actualizar el módulo con las dependencias adecuadas
    echo "Ejecutando go mod tidy para $module_name"
    go mod tidy -v
    
    # Crear go.sum si no existe
    if [ ! -f go.sum ]; then
        echo "Creando go.sum para $module_name"
        # Truco para forzar la creación de go.sum
        go mod download
    fi
    
    echo "✅ Módulo $module_name inicializado correctamente"
    echo ""
}

# Generar código Go desde proto para cada componente
echo "===== Generando código desde proto para go-api ====="
cd "$PROJECT_DIR/go-api" || exit 1

# Primero inicializamos el módulo con las dependencias básicas
init_go_module "$PROJECT_DIR/go-api" "go-api" \
    "github.com/gin-gonic/gin@v1.9.1" \
    "google.golang.org/grpc@v1.58.3" \
    "google.golang.org/grpc/credentials/insecure@v1.58.3" \
    "google.golang.org/protobuf@v1.31.0"

# Ahora generamos el código proto
echo "Generando archivos proto para go-api..."
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       proto/weathertweet.proto

# Actualizamos el módulo después de generar el código proto
go mod tidy -v

echo "===== Generando código desde proto para kafka-writer ====="
cd "$PROJECT_DIR/go-writers/kafka" || exit 1

# Inicializamos el módulo con las dependencias básicas
init_go_module "$PROJECT_DIR/go-writers/kafka" "kafka-writer" \
    "github.com/confluentinc/confluent-kafka-go/v2@v2.3.0" \
    "google.golang.org/grpc@v1.58.3" \
    "google.golang.org/grpc/reflection@v1.58.3" \
    "google.golang.org/protobuf@v1.31.0"

# Generamos el código proto
echo "Generando archivos proto para kafka-writer..."
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       proto/weathertweet.proto

# Actualizamos el módulo después de generar el código proto
go mod tidy -v

echo "===== Generando código desde proto para rabbit-writer ====="
cd "$PROJECT_DIR/go-writers/rabbit" || exit 1

# Inicializamos el módulo con las dependencias básicas
init_go_module "$PROJECT_DIR/go-writers/rabbit" "rabbit-writer" \
    "github.com/streadway/amqp@v1.1.0" \
    "google.golang.org/grpc@v1.58.3" \
    "google.golang.org/grpc/reflection@v1.58.3" \
    "google.golang.org/protobuf@v1.31.0"

# Generamos el código proto
echo "Generando archivos proto para rabbit-writer..."
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       proto/weathertweet.proto

# Actualizamos el módulo después de generar el código proto
go mod tidy -v

echo "===== Inicializando módulos para kafka-consumer ====="
cd "$PROJECT_DIR/go-consumers/kafka" || exit 1

# Inicializamos el módulo con las dependencias básicas
init_go_module "$PROJECT_DIR/go-consumers/kafka" "kafka-consumer" \
    "github.com/confluentinc/confluent-kafka-go/v2@v2.3.0" \
    "github.com/go-redis/redis/v8@v8.11.5"

# Actualizamos el módulo después de generar el código proto
go mod tidy -v

echo "===== Inicializando módulos para rabbit-consumer ====="
cd "$PROJECT_DIR/go-consumers/rabbit" || exit 1

# Inicializamos el módulo con las dependencias básicas
init_go_module "$PROJECT_DIR/go-consumers/rabbit" "rabbit-consumer" \
    "github.com/streadway/amqp@v1.1.0" \
    "github.com/go-redis/redis/v8@v8.11.5"

# Actualizamos el módulo después de generar el código proto
go mod tidy -v

echo "✅ Inicialización de módulos Go completada exitosamente."
cd "$PROJECT_DIR"