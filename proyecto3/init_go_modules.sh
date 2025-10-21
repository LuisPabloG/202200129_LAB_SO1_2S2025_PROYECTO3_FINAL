#!/bin/bash

echo "Preparando módulos Go..."

# Generar proto y luego inicializar módulos de Go
# Para cada uno, vamos a inicializar el módulo, obtener dependencias y generar go.sum

# Directorio raíz del proyecto
PROJECT_DIR=$(pwd)

# Crear directorios proto para cada componente Go
mkdir -p go-api/proto
mkdir -p go-writers/kafka/proto
mkdir -p go-writers/rabbit/proto
mkdir -p go-consumers/kafka/proto
mkdir -p go-consumers/rabbit/proto

# Copiar archivo proto a cada componente
cp proto/weathertweet.proto go-api/proto/
cp proto/weathertweet.proto go-writers/kafka/proto/
cp proto/weathertweet.proto go-writers/rabbit/proto/
cp proto/weathertweet.proto go-consumers/kafka/proto/
cp proto/weathertweet.proto go-consumers/rabbit/proto/

# Instalar protoc-gen-go y protoc-gen-go-grpc si no están ya instalados
if ! command -v protoc-gen-go &> /dev/null; then
    echo "Instalando protoc-gen-go..."
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
fi

if ! command -v protoc-gen-go-grpc &> /dev/null; then
    echo "Instalando protoc-gen-go-grpc..."
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
fi

# Asegurarnos que los binarios están en el PATH
export PATH="$PATH:$(go env GOPATH)/bin"

# Función para inicializar un módulo Go
init_go_module() {
    local directory=$1
    local module_name=$2
    
    echo "Inicializando módulo en $directory como $module_name..."
    cd $directory
    
    # Asegurarnos de que sea un módulo Go
    if [ ! -f go.mod ]; then
        go mod init $module_name
    fi
    
    # Actualizar el módulo con las dependencias adecuadas
    go mod tidy
    
    # Verificar resultado
    if [ $? -ne 0 ]; then
        echo "ERROR: No se pudo inicializar el módulo en $directory"
    else
        echo "Módulo inicializado correctamente en $directory"
    fi
}

# Generar código Go desde proto para cada componente
echo "Generando código desde proto para go-api..."
cd $PROJECT_DIR/go-api
init_go_module "$PROJECT_DIR/go-api" "go-api"
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       proto/weathertweet.proto
go get google.golang.org/grpc@v1.58.3
go mod tidy

echo "Generando código desde proto para kafka-writer..."
cd $PROJECT_DIR/go-writers/kafka
init_go_module "$PROJECT_DIR/go-writers/kafka" "kafka-writer"
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       proto/weathertweet.proto
go get github.com/confluentinc/confluent-kafka-go/v2@v2.3.0
go get google.golang.org/grpc@v1.58.3
go mod tidy

echo "Generando código desde proto para rabbit-writer..."
cd $PROJECT_DIR/go-writers/rabbit
init_go_module "$PROJECT_DIR/go-writers/rabbit" "rabbit-writer"
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       proto/weathertweet.proto
go get github.com/streadway/amqp@v1.1.0
go get google.golang.org/grpc@v1.58.3
go mod tidy

echo "Inicializando módulos para kafka-consumer..."
cd $PROJECT_DIR/go-consumers/kafka
init_go_module "$PROJECT_DIR/go-consumers/kafka" "kafka-consumer"
go get github.com/confluentinc/confluent-kafka-go/v2@v2.3.0
go get github.com/go-redis/redis/v8@v8.11.5
go mod tidy

echo "Inicializando módulos para rabbit-consumer..."
cd $PROJECT_DIR/go-consumers/rabbit
init_go_module "$PROJECT_DIR/go-consumers/rabbit" "rabbit-consumer"
go get github.com/streadway/amqp@v1.1.0
go get github.com/go-redis/redis/v8@v8.11.5
go mod tidy

echo "Inicialización de módulos Go completada."
cd $PROJECT_DIR