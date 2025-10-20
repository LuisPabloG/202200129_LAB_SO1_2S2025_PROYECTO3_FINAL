#!/bin/bash

echo "Creando una nueva instancia de Grafana desde cero..."

# Eliminar completamente la instalación anterior de Grafana
kubectl delete deployment grafana -n sopes3 --ignore-not-found
kubectl delete service grafana-service -n sopes3 --ignore-not-found
kubectl delete configmap grafana-ini-config -n sopes3 --ignore-not-found
kubectl delete configmap grafana-datasources -n sopes3 --ignore-not-found
kubectl delete configmap grafana-dashboards -n sopes3 --ignore-not-found
kubectl delete persistentvolumeclaim grafana-pvc -n sopes3 --ignore-not-found

echo "Esperando a que se eliminen los recursos anteriores..."
sleep 5

# Crear una nueva instancia de Grafana con configuración simple
kubectl apply -f - <<YAML
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-simple
  namespace: sopes3
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana-simple
  template:
    metadata:
      labels:
        app: grafana-simple
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:9.5.2
        env:
        - name: GF_SECURITY_ADMIN_USER
          value: "admin"
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "adminadmin"
        - name: GF_USERS_ALLOW_SIGN_UP
          value: "false"
        - name: GF_AUTH_ANONYMOUS_ENABLED
          value: "true"
        - name: GF_AUTH_ANONYMOUS_ORG_ROLE
          value: "Admin"
        - name: GF_AUTH_DISABLE_LOGIN_FORM
          value: "false"
        - name: GF_AUTH_BASIC_ENABLED
          value: "true"
        - name: GF_INSTALL_PLUGINS
          value: "grafana-clock-panel,grafana-simple-json-datasource,grafana-piechart-panel"
        ports:
        - containerPort: 3000
          name: http
        readinessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 30
          timeoutSeconds: 2
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-simple-service
  namespace: sopes3
spec:
  selector:
    app: grafana-simple
  ports:
  - port: 3000
    targetPort: 3000
  type: LoadBalancer
YAML

echo "Esperando a que la nueva instancia de Grafana esté disponible..."
kubectl get pods -n sopes3 -l app=grafana-simple -w &
WATCH_PID=$!

# Esperar a que el pod esté listo
sleep 10
kill $WATCH_PID

# Obtener la IP externa
echo "Esperando a que se asigne la IP externa..."
sleep 20
GRAFANA_IP=$(kubectl get service grafana-simple-service -n sopes3 -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
GRAFANA_PORT="3000"

echo "======================================"
echo "Nueva instancia de Grafana creada con éxito"
echo "Accede usando: http://${GRAFANA_IP}:${GRAFANA_PORT}"
echo "Usuario: admin"
echo "Contraseña: adminadmin"
echo "======================================"

echo "Ahora puedes importar el dashboard manualmente desde la interfaz web."
echo "1. Inicia sesión con las credenciales proporcionadas"
echo "2. Haz clic en + -> Import"
echo "3. Haz clic en 'Upload JSON file'"
echo "4. Selecciona el archivo grafana-dashboard-manual.json"