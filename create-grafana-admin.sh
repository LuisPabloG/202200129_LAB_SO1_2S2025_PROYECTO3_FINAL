#!/bin/bash

# Script para crear una nueva instancia de Grafana con permisos completos de administrador
# Este script despliega una instancia de Grafana con todos los permisos necesarios

# Variables de configuración
NAMESPACE="default"
GRAFANA_DEPLOYMENT="grafana-admin"
GRAFANA_SERVICE="grafana-admin-svc"
GRAFANA_CONFIG_MAP="grafana-admin-config"
GRAFANA_PORT=3000
GRAFANA_TARGET_PORT=3000

echo "=== Creando una nueva instancia de Grafana con permisos de administrador ==="

# 1. Crear un ConfigMap con la configuración que incluye permisos de administrador
kubectl create configmap $GRAFANA_CONFIG_MAP --from-literal=grafana.ini="
[security]
admin_user = admin
admin_password = admin
disable_initial_admin_creation = false

[auth.anonymous]
enabled = true
org_role = Admin

[plugins]
allow_loading_unsigned_plugins = true
app_tls_skip_verify_insecure = true

[server]
root_url = %(protocol)s://%(domain)s:%(http_port)s/
serve_from_sub_path = true

[users]
allow_sign_up = false
auto_assign_org = true
auto_assign_org_role = Admin

[auth]
disable_login_form = false
disable_signout_menu = false
" -n $NAMESPACE

echo "✅ ConfigMap de configuración creado"

# 2. Crear un deployment de Grafana con la configuración adecuada
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $GRAFANA_DEPLOYMENT
  namespace: $NAMESPACE
  labels:
    app: grafana-admin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana-admin
  template:
    metadata:
      labels:
        app: grafana-admin
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
          name: grafana-http
        env:
        - name: GF_SECURITY_ADMIN_USER
          value: "admin"
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin"
        - name: GF_INSTALL_PLUGINS
          value: "redis-datasource"
        - name: GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS
          value: "true"
        - name: GF_SERVER_ROOT_URL
          value: "%(protocol)s://%(domain)s:%(http_port)s/"
        - name: GF_USERS_ALLOW_SIGN_UP
          value: "false"
        - name: GF_USERS_AUTO_ASSIGN_ORG_ROLE
          value: "Admin"
        - name: GF_AUTH_ANONYMOUS_ENABLED
          value: "true"
        - name: GF_AUTH_ANONYMOUS_ORG_ROLE
          value: "Admin"
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
        - name: grafana-config
          mountPath: /etc/grafana/grafana.ini
          subPath: grafana.ini
      volumes:
      - name: grafana-storage
        emptyDir: {}
      - name: grafana-config
        configMap:
          name: $GRAFANA_CONFIG_MAP
EOF

echo "✅ Nuevo deployment de Grafana con permisos de administrador creado"

# 3. Esperar a que el pod esté listo
echo "⏳ Esperando a que el pod de Grafana esté listo..."
kubectl wait --for=condition=ready pod -l app=grafana-admin -n $NAMESPACE --timeout=120s

# 4. Crear un servicio LoadBalancer para exponer Grafana
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: $GRAFANA_SERVICE
  namespace: $NAMESPACE
  labels:
    app: grafana-admin
  annotations:
    cloud.google.com/load-balancer-type: "External"
spec:
  type: LoadBalancer
  ports:
  - port: $GRAFANA_PORT
    targetPort: $GRAFANA_TARGET_PORT
    protocol: TCP
    name: http
  selector:
    app: grafana-admin
EOF

echo "✅ Servicio LoadBalancer para Grafana creado"

# 5. Esperar a obtener la IP externa
echo "⏳ Esperando a que se asigne una IP externa al servicio..."
EXTERNAL_IP=""
while [ -z $EXTERNAL_IP ]; do
  echo "Esperando IP externa..."
  EXTERNAL_IP=$(kubectl get svc $GRAFANA_SERVICE -n $NAMESPACE --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
  [ -z "$EXTERNAL_IP" ] && sleep 10
done

echo "✅ ¡Configuración completada!"
echo "📊 Nueva instancia de Grafana con permisos completos disponible en:"
echo "   http://$EXTERNAL_IP:$GRAFANA_PORT"
echo ""
echo "   Usuario: admin"
echo "   Contraseña: admin"
echo ""
echo "   Esta instancia tiene el plugin de Redis preinstalado y permisos completos"
echo "   para administrar datasources, plugins y todos los aspectos de Grafana."