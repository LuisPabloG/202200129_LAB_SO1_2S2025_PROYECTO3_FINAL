#!/bin/bash

# Script para restablecer las credenciales de Grafana

echo "Restableciendo las credenciales de Grafana..."

# Eliminar el pod de Grafana para que se reinicie con credenciales predeterminadas
echo "Eliminando el deployment actual de Grafana..."
kubectl delete deployment grafana -n sopes3

# Crear una configuración personalizada para Grafana
kubectl apply -f - <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-ini-config
  namespace: sopes3
data:
  grafana.ini: |
    [security]
    admin_user = admin
    admin_password = admin
    disable_initial_admin_creation = true

    [auth]
    disable_login_form = false
    disable_signout_menu = false

    [auth.anonymous]
    enabled = true
    org_role = Viewer
YAML

# Crear un nuevo deployment de Grafana con la configuración personalizada
kubectl apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: sopes3
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
          name: http
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
          value: "Viewer"
        volumeMounts:
        - name: grafana-ini
          mountPath: /etc/grafana/grafana.ini
          subPath: grafana.ini
      volumes:
      - name: grafana-ini
        configMap:
          name: grafana-ini-config
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  namespace: sopes3
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: LoadBalancer
YAML

echo "Esperando a que el nuevo pod de Grafana esté disponible..."
sleep 10
kubectl get pods -n sopes3 | grep grafana

# Esperar a que Grafana esté disponible
echo "Esperando a que Grafana esté listo (esto puede tomar un minuto)..."
POD_NAME=$(kubectl get pods -n sopes3 -l app=grafana -o jsonpath='{.items[0].metadata.name}')

# Verificar que el pod esté listo
kubectl wait --for=condition=Ready pod/$POD_NAME -n sopes3 --timeout=120s

# Obtener la IP externa
GRAFANA_IP=$(kubectl get service grafana-service -n sopes3 -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
GRAFANA_PORT="3000"

echo "======================================"
echo "Grafana ha sido restablecido con éxito"
echo "Accede usando: http://${GRAFANA_IP}:${GRAFANA_PORT}"
echo "Usuario: admin"
echo "Contraseña: admin"
echo "======================================"
echo "Después de acceder, ejecuta el script create-grafana-dashboard.sh para crear los dashboards"