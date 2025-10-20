#!/bin/bash

# Script para resolver problemas de acceso directo a Grafana a través de la IP externa
# Este script configura Grafana para permitir acceso externo sin problemas

echo "Solucionando problemas de acceso directo a Grafana..."

# Obtener la IP externa actual de Grafana
GRAFANA_IP=$(kubectl get service grafana-service -n sopes3 -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "IP externa actual de Grafana: $GRAFANA_IP"

# 1. Eliminar el servicio y despliegue actuales
echo "Eliminando servicio y despliegue actuales de Grafana..."
kubectl delete service grafana-service -n sopes3 --ignore-not-found
kubectl delete deployment grafana -n sopes3 --ignore-not-found
sleep 5

# 2. Crear un ConfigMap con configuración para acceso externo
echo "Creando ConfigMap con configuración optimizada..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-config
  namespace: sopes3
data:
  grafana.ini: |
    [server]
    domain = ${GRAFANA_IP}
    root_url = http://${GRAFANA_IP}:3000
    serve_from_sub_path = false
    
    [security]
    admin_user = admin
    admin_password = admin
    disable_initial_admin_creation = false
    
    [auth]
    disable_login_form = false
    
    [auth.anonymous]
    enabled = true
    org_role = Admin
    
    [paths]
    provisioning = /etc/grafana/provisioning
    
    [users]
    allow_sign_up = false
EOF

# 3. Crear un nuevo despliegue de Grafana optimizado para acceso externo
echo "Creando nuevo despliegue de Grafana..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-external
  namespace: sopes3
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana-external
  template:
    metadata:
      labels:
        app: grafana-external
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:9.5.2
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_USER
          value: "admin"
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin"
        - name: GF_USERS_ALLOW_SIGN_UP
          value: "false"
        - name: GF_AUTH_ANONYMOUS_ENABLED
          value: "true"
        - name: GF_AUTH_ANONYMOUS_ORG_ROLE
          value: "Admin"
        - name: GF_SERVER_DOMAIN
          value: "${GRAFANA_IP}"
        - name: GF_SERVER_ROOT_URL
          value: "http://${GRAFANA_IP}:3000"
        - name: GF_SERVER_SERVE_FROM_SUB_PATH
          value: "false"
        - name: GF_SERVER_ENABLE_GZIP
          value: "true"
        - name: GF_DATABASE_TYPE
          value: "sqlite3"
        volumeMounts:
        - name: grafana-config
          mountPath: /etc/grafana/grafana.ini
          subPath: grafana.ini
      volumes:
      - name: grafana-config
        configMap:
          name: grafana-config
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-external-service
  namespace: sopes3
spec:
  selector:
    app: grafana-external
  ports:
  - port: 3000
    targetPort: 3000
  type: LoadBalancer
EOF

# 4. Esperar a que el nuevo pod esté disponible
echo "Esperando a que el nuevo pod esté disponible..."
sleep 10
kubectl get pods -n sopes3 -l app=grafana-external -w &
WATCH_PID=$!
sleep 15
kill $WATCH_PID

# 5. Obtener la nueva IP externa
echo "Esperando a que se asigne la IP externa..."
sleep 30
NEW_GRAFANA_IP=$(kubectl get service grafana-external-service -n sopes3 -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
NEW_GRAFANA_PORT="3000"

# 6. Configurar el dashboard por defecto
echo "Configurando el dashboard por defecto..."
sleep 10

# 7. Mostrar información de acceso
echo "======================================"
echo "Nueva instancia de Grafana optimizada para acceso externo"
echo "Accede usando: http://${NEW_GRAFANA_IP}:${NEW_GRAFANA_PORT}"
echo "Usuario: admin"
echo "Contraseña: admin"
echo "======================================"
echo "Si esta instancia no funciona para acceso externo, usa el método de port-forwarding:"
echo "./grafana-port-forward.sh"
echo "======================================"

# 8. Verificar servicios disponibles
kubectl get services -n sopes3 | grep grafana