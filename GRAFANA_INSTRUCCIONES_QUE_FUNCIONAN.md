# Instrucciones para Acceder a Grafana (MÉTODO QUE FUNCIONA)

## 1. Actualiza el repositorio
```bash
cd ~/202200129_LAB_SO1_2S2025_PROYECTO3_FINAL
git pull origin main
```

## 2. Usa port-forwarding para acceder a Grafana
Este método funciona correctamente para acceder a Grafana:
```bash
./grafana-port-forward.sh
```

## 3. Accede a Grafana
Una vez que el port-forwarding esté establecido, abre en tu navegador:
```
http://localhost:8080
```

## 4. Importa el Dashboard
1. Una vez dentro de Grafana, haz clic en el icono "+" en la barra lateral izquierda
2. Selecciona "Import"
3. Haz clic en "Upload JSON file"
4. Selecciona el archivo `grafana-dashboard-manual.json` de tu sistema local
   (Nota: puedes descargarlo primero con `cat grafana-dashboard-manual.json > dashboard.json`)
5. Haz clic en "Import"

## 5. Simulación de Datos del Clima
Para simular el envío de datos de clima, ejecuta en otra terminal (manteniendo abierta la del port-forwarding):
```bash
# Obtener la IP del ingress
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Enviar datos simulados
curl -X POST http://${INGRESS_IP}/tweet \
  -H "Content-Type: application/json" \
  -d '{"municipality": "chinautla", "temperature": 25, "humidity": 75, "weather": "sunny"}'
```

## IMPORTANTE:
- **Mantén la terminal con el port-forwarding abierta** mientras usas Grafana
- Si necesitas cerrar el port-forwarding, presiona Ctrl+C
- Si cierras la terminal, tendrás que ejecutar nuevamente `./grafana-port-forward.sh`