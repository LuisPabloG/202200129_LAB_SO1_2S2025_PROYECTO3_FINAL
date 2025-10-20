# Instrucciones para Acceder a Grafana

Este documento presenta diferentes métodos para acceder a tu instancia de Grafana en el clúster de Kubernetes.

## 1. Actualiza tu repositorio

Antes de comenzar, asegúrate de tener los scripts más recientes:

```bash
cd ~/202200129_LAB_SO1_2S2025_PROYECTO3_FINAL
git pull origin main
```

## 2. Método 1: Acceso por Port-Forwarding (MÉTODO GARANTIZADO)

Este método siempre funciona, pero requiere mantener el terminal abierto:

```bash
./grafana-port-forward.sh
```

Una vez establecido el port-forwarding, accede a Grafana en tu navegador:
```
http://localhost:8080
```

## 3. Método 2: Acceso por IP Externa de LoadBalancer

Si prefieres acceder directamente por la IP externa (sin port-forwarding):

```bash
# Ejecuta el script para configurar un servicio LoadBalancer para Grafana
./fix-grafana-external-access.sh
```

El script mostrará la URL de acceso al finalizar (algo como http://35.x.x.x:3000)

## 4. Método 3: Acceso a través de Ingress

Para acceder a Grafana mediante un controlador Ingress:

```bash
# Configura el Ingress para Grafana
./setup-grafana-ingress.sh
```

El script mostrará la URL de acceso al finalizar (algo como http://34.x.x.x/grafana)

## Credenciales de acceso

Para todos los métodos de acceso, utiliza:
- Usuario: admin
- Contraseña: admin

## Solución de problemas

Si encuentras dificultades para acceder a Grafana:

1. **Verifica el estado de los recursos**:
   ```bash
   kubectl get pods -l app=grafana
   kubectl get service grafana
   kubectl get ingress grafana-ingress
   ```

2. **Verifica los logs**:
   ```bash
   kubectl logs -l app=grafana
   ```

3. **Si los métodos de acceso externo no funcionan**:
   Siempre puedes volver al método de port-forwarding que es más confiable.