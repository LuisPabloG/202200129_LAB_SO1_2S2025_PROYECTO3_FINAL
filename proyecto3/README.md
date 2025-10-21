# Documentación Técnica - Proyecto 3 SOPES

**Nombre:** Luis Pablo García  
**Carnet:** 202200129  
**Curso:** Sistemas Operativos 1

## Arquitectura del Sistema

El sistema "Tweets del Clima" implementa una arquitectura de microservicios distribuida en Google Kubernetes Engine (GKE), que simula la recepción, procesamiento y visualización de "tweets" sobre el clima de diferentes municipios de Guatemala. La arquitectura sigue un diseño basado en contenedores orquestados por Kubernetes, con múltiples componentes que se comunican entre sí.

### Componentes del Sistema

1. **Locust**: Generador de tráfico que simula la creación de tweets con información del clima.

2. **API REST (Rust)**: Recibe las peticiones HTTP desde Locust y las reenvía al servicio Go.

3. **API Go (REST y gRPC Client)**: Recibe las peticiones de la API Rust y actúa como cliente gRPC para enviar datos a los writers.

4. **Writers gRPC (Go)**: Dos servicios que publican los mensajes en Kafka y RabbitMQ respectivamente.

5. **Message Brokers**: Kafka y RabbitMQ para el manejo asíncrono de mensajes.

6. **Consumers (Go)**: Dos servicios que consumen mensajes desde Kafka y RabbitMQ y los almacenan en Valkey.

7. **Valkey**: Base de datos en memoria compatible con Redis para almacenar los datos procesados.

8. **Grafana**: Visualización de datos almacenados en Valkey.

9. **Zot Registry**: Registro privado de Docker para almacenar las imágenes de los componentes.

### Flujo de Datos

1. Locust genera tweets simulados con información del clima para el municipio de Chinautla.
2. Estos tweets son enviados a la API Rust a través del Ingress NGINX.
3. La API Rust procesa las peticiones y las reenvía a la API Go.
4. La API Go las recibe y, utilizando gRPC, envía los tweets a los writers.
5. Los writers publican los mensajes en sus respectivos brokers (Kafka y RabbitMQ).
6. Los consumers consumen estos mensajes y los almacenan en la base de datos Valkey.
7. Grafana visualiza los datos almacenados en Valkey en un dashboard personalizado.

## Implementación de Componentes

### API Rust (REST)

La API REST en Rust se encarga de recibir los tweets y reenviarlos al servicio Go. Está configurada para escalar automáticamente entre 1 y 3 réplicas cuando la utilización de CPU supera el 30%.

#### Características principales:
- Implementada con el framework Actix-Web
- Manejo de concurrencia mediante Tokio
- Endpoints para health check y recepción de tweets
- Configuración de HPA para escalamiento automático

### API Go (gRPC Client)

Este servicio actúa como intermediario entre la API Rust y los escritores gRPC. Recibe peticiones REST y las distribuye a los servicios de Kafka y RabbitMQ mediante llamadas gRPC concurrentes.

#### Características principales:
- Implementada con el framework Gin para la API REST
- Cliente gRPC para comunicación con los writers
- Procesamiento concurrente con goroutines

### Writers gRPC (Go)

Se implementaron dos servicios gRPC en Go para la publicación de mensajes en Kafka y RabbitMQ respectivamente.

#### Características principales:
- Servidor gRPC para recibir mensajes
- Publicación en Kafka y RabbitMQ respectivamente
- Manejo de errores y reconexiones

### Consumers (Go)

Los consumidores se encargan de leer los mensajes de los brokers y almacenarlos en Valkey. Se implementaron dos consumidores, uno para Kafka y otro para RabbitMQ.

#### Características principales:
- Lectura continua de mensajes de los brokers
- Procesamiento y transformación de datos
- Almacenamiento en Valkey con TTL para evitar saturación
- Manejo de métricas y agregaciones para el dashboard

### Valkey (Redis compatible)

Base de datos en memoria compatible con Redis, utilizada para almacenar los datos procesados. Se configuró con dos réplicas para garantizar la persistencia.

#### Características principales:
- Almacenamiento de datos con TTL
- Configuración de memoria máxima y política de evicción
- Alta disponibilidad con múltiples réplicas

## Configuración de Kubernetes

### Namespaces

Todo el sistema se despliega en un namespace dedicado llamado `proyecto3`.

### Ingress

El Ingress NGINX se encarga de exponer los servicios externos (API Rust, Locust y Grafana) a través de diferentes rutas.

### Deployments y Services

Cada componente se despliega como un Deployment de Kubernetes con su correspondiente Service para comunicación interna.

### HPA (Horizontal Pod Autoscaler)

Se configuró un HPA para la API Rust que permite escalar entre 1 y 3 réplicas basado en la utilización de CPU.

## Pruebas y Análisis de Rendimiento

### Comparación entre Kafka y RabbitMQ

Durante las pruebas de carga, se observaron diferencias significativas entre Kafka y RabbitMQ:

- **Kafka**: Mayor throughput para grandes volúmenes de mensajes, pero mayor latencia inicial.
- **RabbitMQ**: Menor latencia para volúmenes pequeños y medianos, pero menor throughput máximo.

### Análisis de Réplicas en Valkey

Se realizaron pruebas con 1 y 2 réplicas de Valkey:
- **1 réplica**: Mayor rendimiento en escritura, pero sin redundancia.
- **2 réplicas**: Mejor disponibilidad y resistencia a fallos, con ligera penalización en rendimiento.

### Comparación REST vs gRPC

- **REST (Rust API a Go API)**: Mayor compatibilidad y facilidad de depuración.
- **gRPC (Go API a Writers)**: Mejor rendimiento, menor overhead y tipado fuerte.

## Conclusiones

1. La arquitectura de microservicios distribuida en Kubernetes permite una gran escalabilidad y resistencia a fallos.

2. La combinación de Rust y Go proporciona un equilibrio entre rendimiento y productividad.

3. Kafka es más adecuado para volúmenes muy grandes de datos, mientras que RabbitMQ ofrece mejor latencia para cargas moderadas.

4. gRPC demuestra un rendimiento superior a REST para comunicaciones internas entre servicios.

5. La configuración de HPA permite que el sistema se adapte automáticamente a diferentes niveles de carga.

## Instrucciones de Despliegue

### Prerrequisitos

- Cluster GKE activo
- VM con Zot Registry configurado
- Docker instalado localmente
- kubectl configurado para acceder al cluster GKE
- Protoc instalado para generación de código gRPC

### Pasos para el Despliegue

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/LuisPabloG/202200129_LAB_SO1_2S2025_PROYECTO3_FINAL.git
   cd 202200129_LAB_SO1_2S2025_PROYECTO3_FINAL/proyecto3
   ```

2. Construir y publicar las imágenes en Zot:
   ```bash
   chmod +x build_and_push.sh
   ./build_and_push.sh
   ```

3. Desplegar en Kubernetes:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

4. Verificar el despliegue:
   ```bash
   kubectl get pods -n proyecto3
   kubectl get services -n proyecto3
   kubectl get ingress -n proyecto3
   ```

5. Acceder a los servicios:
   - Locust: http://<INGRESS_IP>/locust
   - Grafana: http://<INGRESS_IP>/grafana (usuario: admin, contraseña: admin)

### Configuración del Dashboard en Grafana

1. Añadir una fuente de datos de tipo Redis apuntando a `valkey-service:6379`
2. Importar el dashboard para visualizar:
   - Total de reportes por municipio (chinautla)
   - Total de reportes por condición climática
   - Temperatura y humedad promedio

## Retos y Soluciones

### Reto 1: Comunicación entre servicios
**Solución**: Implementación de gRPC para comunicación eficiente y tipada.

### Reto 2: Escalabilidad y rendimiento
**Solución**: Configuración de HPA y optimización de recursos.

### Reto 3: Persistencia de datos en Valkey
**Solución**: Implementación de TTL y configuración de múltiples réplicas.

### Reto 4: Configuración de Ingress
**Solución**: Uso de anotaciones específicas para NGINX Ingress Controller.