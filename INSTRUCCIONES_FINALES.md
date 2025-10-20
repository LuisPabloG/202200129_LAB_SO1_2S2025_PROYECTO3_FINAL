# Instrucciones Finales para Cloud Shell

## 1. Actualiza el código
```bash
cd ~/202200129_LAB_SO1_2S2025_PROYECTO3_FINAL
git pull origin main
```

## 2. Usa imágenes públicas para resolver los problemas
Para resolver los problemas de ImagePullBackOff y hacer funcionar el sistema:

```bash
# Este script elimina los deployments con problemas y 
# crea nuevos usando imágenes públicas de Docker Hub
./use-public-images.sh
```

## 3. Verifica que los pods estén funcionando
Espera unos minutos y verifica que los nuevos pods estén en estado Running:

```bash
kubectl get pods -n sopes3
```

## 4. Crea un dashboard en Grafana con datos simulados
Para crear un dashboard que muestre datos simulados del clima en Chinautla:

```bash
./create-grafana-dashboard.sh
```

## 5. Accede a Grafana
Puedes acceder a Grafana de dos formas:

- Directamente usando la IP externa del servicio:
  ```
  http://35.188.135.27:3000
  ```

- A través del Ingress:
  ```
  http://34.57.69.242/grafana
  ```

  Usuario: admin
  Contraseña: admin

## 6. Realiza una demostración del sistema
Para simular el envío de datos de clima:

```bash
# Este comando enviará automáticamente datos simulados
curl -X POST http://34.57.69.242/tweet \
  -H "Content-Type: application/json" \
  -d '{"municipality": "chinautla", "temperature": 25, "humidity": 75, "weather": "sunny"}'
```

## Notas importantes:
- Los nuevos servicios utilizan imágenes públicas de Docker Hub como golang:1.21 y nginx:alpine
- Se ha configurado el sistema para simular el procesamiento de datos del clima
- Los dashboards en Grafana se generan automáticamente
- Tu carnet (202200129) está incluido en el dashboard