#!/bin/bash

# Script para verificar las credenciales de Grafana

echo "Verificando instancias de Grafana..."

# Listar todos los pods de Grafana
kubectl get pods -n sopes3 | grep grafana

# Obtener información sobre los servicios de Grafana
echo -e "\nInformación de servicios Grafana:"
kubectl get services -n sopes3 | grep grafana

# Obtener IPs externas
echo -e "\nIPs externas de Grafana:"
kubectl get services -n sopes3 -o custom-columns=NAME:.metadata.name,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip | grep grafana

# Listar posibles secretos con credenciales
echo -e "\nPosibles secretos con credenciales:"
kubectl get secrets -n sopes3 | grep grafana

# Verificar variables de entorno en pods de Grafana
echo -e "\nVariables de entorno de los pods de Grafana:"
PODS=$(kubectl get pods -n sopes3 | grep grafana | awk '{print $1}')
for POD in $PODS; do
    echo -e "\nPod: $POD"
    kubectl exec -n sopes3 $POD -- env | grep -i GF_SECURITY || echo "No se encontraron variables de seguridad"
done

echo -e "\nIntentando mostrar la configuración de Grafana:"
for POD in $PODS; do
    echo -e "\nPod: $POD"
    kubectl exec -n sopes3 $POD -- cat /etc/grafana/grafana.ini 2>/dev/null | grep -i "admin_" || echo "No se pudo leer el archivo de configuración"
done

echo -e "\nPrueba estas credenciales comunes:"
echo "1. admin / admin"
echo "2. admin / adminadmin"
echo "3. admin / password"
echo "4. admin / prom-operator"
echo "5. admin / grafana"
echo "6. grafana / grafana"

echo -e "\nSi ninguna de estas funciona, ejecuta ./new-grafana-instance.sh para crear una nueva instancia con credenciales conocidas."