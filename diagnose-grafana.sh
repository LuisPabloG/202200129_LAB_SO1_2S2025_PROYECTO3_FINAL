#!/bin/bash

# Script para verificar y solucionar problemas comunes de Grafana
# Este script proporciona diagnósticos y soluciones para problemas de acceso

# Variables de configuración
NAMESPACE="default"
GRAFANA_SERVICE="grafana"
GRAFANA_PORT=3000
GRAFANA_DEPLOYMENT="grafana"

echo "=== Diagnóstico de Problemas de Grafana ==="
echo "Ejecutando verificaciones..."

# 1. Verificar si el pod de Grafana está en ejecución
echo "1. Verificando pods de Grafana..."
GRAFANA_PODS=$(kubectl get pods -n $NAMESPACE -l app=grafana -o jsonpath='{.items[*].status.phase}')

if [[ -z "$GRAFANA_PODS" ]]; then
    echo "❌ No se encontraron pods de Grafana en ejecución."
    echo "   Solución: Verifica que el deployment esté correcto."
    
    # Mostrar deployments existentes
    echo "   Deployments existentes:"
    kubectl get deployments -n $NAMESPACE | grep -i grafana
else
    echo "✅ Pods de Grafana encontrados: $GRAFANA_PODS"
    
    # Mostrar pods con más detalle
    echo "   Detalles de los pods:"
    kubectl get pods -n $NAMESPACE -l app=grafana -o wide
fi

# 2. Verificar el servicio de Grafana
echo ""
echo "2. Verificando el servicio de Grafana..."
GRAFANA_SVC=$(kubectl get svc -n $NAMESPACE $GRAFANA_SERVICE 2>/dev/null)

if [[ $? -ne 0 ]]; then
    echo "❌ No se encontró el servicio '$GRAFANA_SERVICE'."
    echo "   Servicios disponibles:"
    kubectl get svc -n $NAMESPACE | grep -i grafana
else
    echo "✅ Servicio de Grafana encontrado:"
    kubectl get svc -n $NAMESPACE $GRAFANA_SERVICE -o wide
    
    # Verificar tipo de servicio
    SVC_TYPE=$(kubectl get svc -n $NAMESPACE $GRAFANA_SERVICE -o jsonpath='{.spec.type}')
    
    if [[ "$SVC_TYPE" == "ClusterIP" ]]; then
        echo "   ⚠️ El servicio es de tipo ClusterIP y no es accesible externamente."
        echo "      Para acceder desde fuera del cluster, considera:"
        echo "      1. Usar port-forwarding: kubectl port-forward svc/$GRAFANA_SERVICE -n $NAMESPACE 8080:$GRAFANA_PORT"
        echo "      2. Cambiar el tipo a LoadBalancer: ./fix-grafana-external-access.sh"
        echo "      3. Configurar un Ingress: ./setup-grafana-ingress.sh"
    elif [[ "$SVC_TYPE" == "LoadBalancer" ]]; then
        EXTERNAL_IP=$(kubectl get svc -n $NAMESPACE $GRAFANA_SERVICE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [[ -z "$EXTERNAL_IP" ]]; then
            echo "   ⚠️ El servicio es tipo LoadBalancer pero aún no tiene IP externa asignada."
            echo "      Esto puede tomar unos minutos. Verifica con:"
            echo "      kubectl get svc -n $NAMESPACE $GRAFANA_SERVICE -o wide"
        else
            echo "   ✅ Accesible en: http://$EXTERNAL_IP:$GRAFANA_PORT"
        fi
    fi
fi

# 3. Verificar Ingress para Grafana
echo ""
echo "3. Verificando Ingress para Grafana..."
GRAFANA_INGRESS=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | grep -i grafana)

if [[ -z "$GRAFANA_INGRESS" ]]; then
    echo "❌ No se encontró ningún Ingress para Grafana."
    echo "   Puedes configurar uno con: ./setup-grafana-ingress.sh"
else
    echo "✅ Ingress para Grafana encontrado:"
    kubectl get ingress -n $NAMESPACE $GRAFANA_INGRESS -o wide
    
    # Obtener dirección del Ingress
    INGRESS_IP=$(kubectl get ingress -n $NAMESPACE $GRAFANA_INGRESS -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    INGRESS_PATH=$(kubectl get ingress -n $NAMESPACE $GRAFANA_INGRESS -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null)
    
    if [[ ! -z "$INGRESS_IP" && ! -z "$INGRESS_PATH" ]]; then
        # Ajustar el path para la URL
        CLEAN_PATH=$(echo $INGRESS_PATH | sed 's/\/\(.*\)\/?.*/\/\1/')
        echo "   ✅ Accesible vía Ingress en: http://$INGRESS_IP$CLEAN_PATH"
    else
        echo "   ⚠️ El Ingress existe pero podría no estar configurado correctamente."
    fi
fi

# 4. Verificar logs de Grafana
echo ""
echo "4. Verificando logs del pod de Grafana..."
GRAFANA_POD=$(kubectl get pods -n $NAMESPACE -l app=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [[ ! -z "$GRAFANA_POD" ]]; then
    echo "Últimas 10 líneas de logs del pod $GRAFANA_POD:"
    kubectl logs -n $NAMESPACE $GRAFANA_POD --tail=10
else
    echo "❌ No se puede obtener logs ya que no se encontraron pods de Grafana."
fi

# 5. Resumen y recomendaciones
echo ""
echo "=== Resumen y Recomendaciones ==="

if [[ -z "$GRAFANA_PODS" || "$GRAFANA_PODS" != *"Running"* ]]; then
    echo "⚠️ Problema principal: Los pods de Grafana no están ejecutándose correctamente."
    echo "   Solución recomendada: Revisar la configuración del deployment y reiniciar Grafana."
elif [[ -z "$GRAFANA_SVC" ]]; then
    echo "⚠️ Problema principal: No existe el servicio de Grafana o está mal configurado."
    echo "   Solución recomendada: Crear un servicio adecuado para Grafana."
elif [[ "$SVC_TYPE" == "ClusterIP" && -z "$GRAFANA_INGRESS" ]]; then
    echo "⚠️ Problema principal: Grafana no es accesible desde fuera del cluster."
    echo "   Soluciones recomendadas:"
    echo "   1. Usar port-forwarding (más simple): ./grafana-port-forward.sh"
    echo "   2. Configurar LoadBalancer: ./fix-grafana-external-access.sh"
    echo "   3. Configurar Ingress: ./setup-grafana-ingress.sh"
else
    echo "✅ Grafana parece estar correctamente configurado."
    echo "   Si aún tienes problemas para acceder, considera:"
    echo "   1. Verificar reglas de firewall en GCP"
    echo "   2. Comprobar que Grafana esté escuchando en la interfaz correcta"
    echo "   3. Verificar las credenciales de acceso (por defecto: admin/admin)"
fi

echo ""
echo "Para acceder a Grafana, prueba los siguientes métodos:"
echo "1. Port-forwarding (método más fiable): ./grafana-port-forward.sh"
echo "   Luego accede a: http://localhost:8080"
echo ""
echo "2. Directo por IP externa (si tienes LoadBalancer):"
EXTERNAL_IP=$(kubectl get svc -n $NAMESPACE -l app=grafana -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [[ ! -z "$EXTERNAL_IP" ]]; then
    echo "   http://$EXTERNAL_IP:$GRAFANA_PORT"
else
    echo "   No hay IP externa disponible aún. Ejecuta: ./fix-grafana-external-access.sh"
fi
echo ""
echo "3. Vía Ingress (si está configurado):"
if [[ ! -z "$INGRESS_IP" && ! -z "$CLEAN_PATH" ]]; then
    echo "   http://$INGRESS_IP$CLEAN_PATH"
else
    echo "   No hay Ingress configurado para Grafana. Ejecuta: ./setup-grafana-ingress.sh"
fi