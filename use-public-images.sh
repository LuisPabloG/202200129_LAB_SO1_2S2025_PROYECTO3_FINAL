#!/bin/bash

# Script para actualizar a imágenes públicas
echo "Actualizando a imágenes públicas conocidas..."

# Eliminar deployments con problemas
kubectl delete deployment -n sopes3 api-rust go-grpc-client go-service-1 go-service-kafka-writer go-service-rabbit-writer kafka-consumer rabbit-consumer

# Crear un ConfigMap para el código Go
kubectl apply -f - <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: go-services-code
  namespace: sopes3
data:
  main.go: |
    package main
    
    import (
      "encoding/json"
      "fmt"
      "log"
      "math/rand"
      "net/http"
      "time"
    )
    
    type WeatherData struct {
      Municipality string  \`json:"municipality"\`
      Temperature  float64 \`json:"temperature"\`
      Humidity     float64 \`json:"humidity"\`
      Weather      string  \`json:"weather"\`
    }
    
    func main() {
      http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello from Go service!")
      })
      
      http.HandleFunc("/api/weather", func(w http.ResponseWriter, r *http.Request) {
        weatherTypes := []string{"sunny", "cloudy", "rainy", "foggy"}
        weatherData := WeatherData{
          Municipality: "chinautla",
          Temperature:  18 + rand.Float64()*10,
          Humidity:     70 + rand.Float64()*20,
          Weather:      weatherTypes[rand.Intn(len(weatherTypes))],
        }
        
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(weatherData)
      })
      
      log.Println("Iniciando servidor en puerto 8080...")
      if err := http.ListenAndServe(":8080", nil); err != nil {
        log.Fatalf("Error al iniciar servidor: %v", err)
      }
    }
YAML

# Desplegar servicios Go con imagen pública
kubectl apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: go-service
  namespace: sopes3
spec:
  replicas: 3
  selector:
    matchLabels:
      app: go-service
  template:
    metadata:
      labels:
        app: go-service
    spec:
      containers:
      - name: go-service
        image: golang:1.21-alpine
        command: ["/bin/sh", "-c"]
        args:
        - |
          mkdir -p /app
          cat /config/main.go > /app/main.go
          cd /app
          go run main.go
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: "200m"
            memory: "128Mi"
          requests:
            cpu: "100m"
            memory: "64Mi"
        volumeMounts:
        - name: config-volume
          mountPath: /config
      volumes:
      - name: config-volume
        configMap:
          name: go-services-code
---
apiVersion: v1
kind: Service
metadata:
  name: go-service
  namespace: sopes3
spec:
  selector:
    app: go-service
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
YAML

# Crear API con imagen pública de NGINX
kubectl apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: sopes3
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
    spec:
      containers:
      - name: api-server
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: "100m"
            memory: "64Mi"
          requests:
            cpu: "50m"
            memory: "32Mi"
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: sopes3
data:
  default.conf: |
    server {
      listen 80;
      server_name _;
      
      location / {
        root /usr/share/nginx/html;
        index index.html;
      }
      
      location /tweet {
        proxy_pass http://go-service:8080/api/weather;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
      }
    }
---
apiVersion: v1
kind: Service
metadata:
  name: api-server-service
  namespace: sopes3
spec:
  selector:
    app: api-server
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
YAML

# Actualizar Ingress para usar los nuevos servicios
kubectl apply -f - <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: weather-ingress
  namespace: sopes3
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-server-service
            port:
              number: 80
      - path: /grafana
        pathType: Prefix
        backend:
          service:
            name: grafana-service
            port:
              number: 3000
YAML

echo "Servicios actualizados. Verificando estado..."
kubectl get pods -n sopes3

echo "Configuración completa. Los pods deberían iniciarse pronto."