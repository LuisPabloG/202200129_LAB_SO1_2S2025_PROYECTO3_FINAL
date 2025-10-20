# Instrucciones para Despliegue en Cloud Shell

## Actualiza tu repositorio
```bash
cd ~/202200129_LAB_SO1_2S2025_PROYECTO3_FINAL
git pull origin main
```

## Arregla los problemas de imágenes
Ejecuta el script para actualizar las rutas de imágenes privadas a públicas:
```bash
./fix-image-issues.sh
```

## Usa imágenes públicas alternativas
Si tienes problemas con ImagePullBackOff, puedes editar manualmente los archivos YAML en la carpeta k8s/ para usar imágenes públicas alternativas:

- Para servicios Go: `golang:1.21` 
- Para API Rust: `rust:1.72`
- Para Kafka: `bitnami/kafka:latest`
- Para RabbitMQ: `rabbitmq:3.12-management`
- Para Valkey: `valkey/valkey:7.2.0`

## Despliega la aplicación
1. Verifica que estás conectado al cluster:
```bash
kubectl get nodes
```

2. Ejecuta el script de despliegue:
```bash
./deploy-k8s.sh
```

3. Espera a que todos los pods estén en estado "Running":
```bash
kubectl get pods -n sopes3 -w
```

4. Una vez que todos los pods estén ejecutándose correctamente, ejecuta las pruebas:
```bash
./test-system.sh
```

## Accede a Grafana
La dirección de Grafana estará disponible en:
```
http://<INGRESS_IP>/grafana
```

O puedes acceder directamente usando la IP del servicio de Grafana:
```bash
kubectl get svc -n sopes3 grafana-service
```

Credenciales:
- Usuario: admin
- Contraseña: admin

## Solución de Problemas

### Usa el script de solución de problemas
Ejecuta el script que reinicia automáticamente todos los deployments:
```bash
./fix-deployment.sh
```

### Si algún pod sigue en ImagePullBackOff
```bash
kubectl describe pod <nombre-del-pod> -n sopes3
```

### Para reiniciar un despliegue específico
```bash
kubectl rollout restart deployment <nombre-deployment> -n sopes3
```

### Para eliminar todos los recursos y empezar de nuevo
```bash
kubectl delete -f ./k8s/0-namespaces.yaml
./deploy-k8s.sh
```

### Si necesitas utilizar imágenes públicas
Si continúas teniendo problemas con las imágenes, puedes crear manualmente un despliegue usando estas imágenes públicas:

```bash
# Desplegar solo los servicios principales
kubectl apply -f ./k8s/0-namespaces.yaml
kubectl apply -f ./k8s/1-nginx-ingress.yaml
kubectl apply -f ./k8s/5-kafka.yaml
kubectl apply -f ./k8s/7-valkey.yaml
kubectl apply -f ./k8s/9-grafana.yaml
kubectl apply -f ./k8s/9.1-grafana-datasource.yaml
kubectl apply -f ./k8s/9.2-grafana-dashboard.yaml
kubectl apply -f ./k8s/10-ingress.yaml
```

## Verificación de Logs
```bash
# Ver logs de un pod específico
kubectl logs <nombre-del-pod> -n sopes3

# Ver logs en tiempo real
kubectl logs -f <nombre-del-pod> -n sopes3
```