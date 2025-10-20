# Guía para Simulaciones con Locust y Dashboard en Grafana

## 1. Configuración de Locust para Simulaciones

### Preparación del Entorno de Simulación

1. **Asegúrate de tener Locust instalado**:
   ```bash
   pip install locust
   ```

2. **Crea un archivo para la simulación de Locust** (si aún no existe):
   ```bash
   touch ~/202200129_LAB_SO1_2S2025_PROYECTO3_FINAL/locustfile.py
   ```

3. **Edita el archivo con el siguiente contenido**:
   ```python
   from locust import HttpUser, task, between
   import random
   import json

   class WeatherTweetUser(HttpUser):
       wait_time = between(0.5, 3)  # Tiempo de espera entre solicitudes (0.5-3 segundos)
       
       # Datos basados en la estructura de tweets del enunciado
       municipalities = ["mixco", "guatemala", "amatitlan", "chinautla"]
       weathers = ["sunny", "cloudy", "rainy", "foggy"]
       
       # Determinar municipio según el último dígito del carnet
       carnet = "202200129"  # Reemplaza con tu número de carnet
       last_digit = int(carnet[-1])
       
       if last_digit in [0, 1, 2]:
           user_municipality = "mixco"
       elif last_digit in [3, 4, 5]:
           user_municipality = "guatemala"
       elif last_digit in [6, 7]:
           user_municipality = "amatitlan"
       else:  # 8, 9
           user_municipality = "chinautla"
       
       @task
       def post_weather_tweet(self):
           # Generar datos aleatorios para el tweet
           temperature = random.randint(10, 35)  # Temperatura entre 10°C y 35°C
           humidity = random.randint(30, 90)     # Humedad entre 30% y 90%
           weather = random.choice(self.weathers) # Condición climática aleatoria
           
           # Crear el objeto JSON para el tweet
           tweet_data = {
               "municipality": self.user_municipality,
               "temperature": temperature,
               "humidity": humidity,
               "weather": weather
           }
           
           # Enviar el tweet a la API REST en Rust
           response = self.client.post(
               "/api/weather",
               json=tweet_data,
               headers={"Content-Type": "application/json"}
           )
           
           # Imprimir información útil para depuración
           print(f"Enviado: {tweet_data}, Respuesta: {response.status_code}")
   ```

### Ejecutar las Simulaciones con Locust

1. **Inicia Locust en la carpeta donde está tu archivo `locustfile.py`**:
   ```bash
   cd ~/202200129_LAB_SO1_2S2025_PROYECTO3_FINAL
   locust --host=http://<IP-DEL-INGRESS>
   ```

2. **Accede a la interfaz web de Locust**:
   - Abre en tu navegador: `http://localhost:8089`
   - Configura el número de usuarios (10 usuarios según el enunciado)
   - Configura la tasa de generación (por ejemplo, 10 usuarios por segundo)
   - Configura un total de 10,000 peticiones según el enunciado
   - Haz clic en "Start swarming" para comenzar la simulación

## 2. Configuración del Dashboard en Grafana

### Acceso a Grafana

1. **Accede a la instancia de Grafana**:
   - URL: http://104.198.150.238:3000
   - Usuario: admin
   - Contraseña: admin

### Creación del Dashboard según Enunciado

1. **Crea un nuevo dashboard**:
   - Haz clic en "+ Create" en la barra lateral izquierda
   - Selecciona "Dashboard"

2. **Agrega un panel para "Total de reportes por condición climática"**:
   - Haz clic en "Add panel"
   - Selecciona "Add a new panel"
   - Configura el tipo de visualización como "Bar chart" (gráfica de barras)
   
   - **Configuración de la consulta**:
     - Datasource: Valkey (o Redis si estás usando este adaptador)
     - Para sunny: `GET sunny_<tu_municipio>`
     - Para cloudy: `GET cloudy_<tu_municipio>`
     - Para rainy: `GET rainy_<tu_municipio>`
     - Para foggy: `GET foggy_<tu_municipio>`
     
     Por ejemplo, para el carnet 202200129 (último dígito 9) que corresponde a "chinautla":
     - `GET sunny_chinautla`
     - `GET cloudy_chinautla`
     - `GET rainy_chinautla`
     - `GET foggy_chinautla`

3. **Agrega un panel para "Temperatura Promedio"**:
   - Haz clic en "Add panel"
   - Selecciona "Add a new panel"
   - Configura el tipo de visualización como "Stat" o "Gauge"
   - Configura la consulta: `GET temperature_<tu_municipio>`
   - Configura las opciones para mostrar la temperatura en grados Celsius

4. **Agrega un panel para "Humedad Promedio"**:
   - Haz clic en "Add panel"
   - Selecciona "Add a new panel"
   - Configura el tipo de visualización como "Gauge"
   - Configura la consulta: `GET humidity_<tu_municipio>`
   - Configura las opciones para mostrar la humedad en porcentaje

5. **Opcional: Agrega un panel de serie temporal para ver la evolución**:
   - Tipo: "Time series"
   - Configura consultas para ver la evolución de temperatura y humedad a lo largo del tiempo

6. **Guarda tu dashboard**:
   - Haz clic en el icono de guardar (disco) en la parte superior derecha
   - Asigna un nombre como "Weather Tweets Dashboard - 202200129"
   - Guarda el dashboard

### Importación de Dashboard Predefinido (Alternativa Rápida)

Si prefieres usar un dashboard predefinido, puedes crear un archivo JSON y luego importarlo:

1. **Crea un archivo JSON para el dashboard**:
   ```bash
   touch ~/202200129_LAB_SO1_2S2025_PROYECTO3_FINAL/grafana-dashboard.json
   ```

2. **Edita el archivo con la definición del dashboard** (ajusta el municipio según tu carnet):
   ```json
   {
     "dashboard": {
       "annotations": {
         "list": [
           {
             "builtIn": 1,
             "datasource": {
               "type": "grafana",
               "uid": "-- Grafana --"
             },
             "enable": true,
             "hide": true,
             "iconColor": "rgba(0, 211, 255, 1)",
             "name": "Anotaciones",
             "target": {
               "limit": 100,
               "matchAny": false,
               "tags": [],
               "type": "dashboard"
             },
             "type": "dashboard"
           }
         ]
       },
       "editable": true,
       "fiscalYearStartMonth": 0,
       "graphTooltip": 0,
       "id": null,
       "links": [],
       "liveNow": false,
       "panels": [
         {
           "datasource": {
             "type": "redis-datasource",
             "uid": "P8E80F9AEF21F6940"
           },
           "fieldConfig": {
             "defaults": {
               "color": {
                 "mode": "palette-classic"
               },
               "custom": {
                 "axisCenteredZero": false,
                 "axisColorMode": "text",
                 "axisLabel": "",
                 "axisPlacement": "auto",
                 "fillOpacity": 80,
                 "gradientMode": "none",
                 "hideFrom": {
                   "legend": false,
                   "tooltip": false,
                   "viz": false
                 },
                 "lineWidth": 1,
                 "scaleDistribution": {
                   "type": "linear"
                 },
                 "thresholdsStyle": {
                   "mode": "off"
                 }
               },
               "mappings": [],
               "thresholds": {
                 "mode": "absolute",
                 "steps": [
                   {
                     "color": "green",
                     "value": null
                   },
                   {
                     "color": "red",
                     "value": 80
                   }
                 ]
               }
             },
             "overrides": []
           },
           "gridPos": {
             "h": 9,
             "w": 12,
             "x": 0,
             "y": 0
           },
           "id": 2,
           "options": {
             "barRadius": 0,
             "barWidth": 0.97,
             "groupWidth": 0.7,
             "legend": {
               "calcs": [],
               "displayMode": "list",
               "placement": "bottom",
               "showLegend": true
             },
             "orientation": "auto",
             "showValue": "auto",
             "stacking": "none",
             "tooltip": {
               "mode": "single",
               "sort": "none"
             },
             "xTickLabelRotation": 0,
             "xTickLabelSpacing": 0
           },
           "targets": [
             {
               "command": "get",
               "keyName": "sunny_chinautla",
               "query": "",
               "refId": "A",
               "type": "command"
             },
             {
               "command": "get",
               "keyName": "cloudy_chinautla",
               "query": "",
               "refId": "B",
               "type": "command"
             },
             {
               "command": "get",
               "keyName": "rainy_chinautla",
               "query": "",
               "refId": "C",
               "type": "command"
             },
             {
               "command": "get",
               "keyName": "foggy_chinautla",
               "query": "",
               "refId": "D",
               "type": "command"
             }
           ],
           "title": "Total de reportes por condición climática",
           "type": "barchart"
         },
         {
           "datasource": {
             "type": "redis-datasource",
             "uid": "P8E80F9AEF21F6940"
           },
           "fieldConfig": {
             "defaults": {
               "color": {
                 "mode": "thresholds"
               },
               "mappings": [],
               "thresholds": {
                 "mode": "absolute",
                 "steps": [
                   {
                     "color": "blue",
                     "value": null
                   },
                   {
                     "color": "green",
                     "value": 20
                   },
                   {
                     "color": "orange",
                     "value": 25
                   },
                   {
                     "color": "red",
                     "value": 30
                   }
                 ]
               },
               "unit": "celsius"
             },
             "overrides": []
           },
           "gridPos": {
             "h": 8,
             "w": 6,
             "x": 12,
             "y": 0
           },
           "id": 4,
           "options": {
             "orientation": "auto",
             "reduceOptions": {
               "calcs": [
                 "lastNotNull"
               ],
               "fields": "",
               "values": false
             },
             "showThresholdLabels": false,
             "showThresholdMarkers": true
           },
           "pluginVersion": "9.5.3",
           "targets": [
             {
               "command": "get",
               "keyName": "temperature_chinautla",
               "query": "",
               "refId": "A",
               "type": "command"
             }
           ],
           "title": "Temperatura Promedio",
           "type": "gauge"
         },
         {
           "datasource": {
             "type": "redis-datasource",
             "uid": "P8E80F9AEF21F6940"
           },
           "fieldConfig": {
             "defaults": {
               "color": {
                 "mode": "thresholds"
               },
               "mappings": [],
               "max": 100,
               "min": 0,
               "thresholds": {
                 "mode": "absolute",
                 "steps": [
                   {
                     "color": "green",
                     "value": null
                   },
                   {
                     "color": "yellow",
                     "value": 50
                   },
                   {
                     "color": "orange",
                     "value": 70
                   },
                   {
                     "color": "red",
                     "value": 85
                   }
                 ]
               },
               "unit": "percent"
             },
             "overrides": []
           },
           "gridPos": {
             "h": 8,
             "w": 6,
             "x": 18,
             "y": 0
           },
           "id": 6,
           "options": {
             "orientation": "auto",
             "reduceOptions": {
               "calcs": [
                 "lastNotNull"
               ],
               "fields": "",
               "values": false
             },
             "showThresholdLabels": false,
             "showThresholdMarkers": true
           },
           "pluginVersion": "9.5.3",
           "targets": [
             {
               "command": "get",
               "keyName": "humidity_chinautla",
               "query": "",
               "refId": "A",
               "type": "command"
             }
           ],
           "title": "Humedad Promedio",
           "type": "gauge"
         }
       ],
       "refresh": "5s",
       "schemaVersion": 38,
       "style": "dark",
       "tags": [],
       "templating": {
         "list": []
       },
       "time": {
         "from": "now-6h",
         "to": "now"
       },
       "timepicker": {},
       "timezone": "",
       "title": "Weather Tweets Dashboard - 202200129",
       "uid": "c60ce2fd-09a2-4471-8f11-71bd1e8e96ef",
       "version": 1,
       "weekStart": ""
     }
   }
   ```

3. **Importa el dashboard en Grafana**:
   - Accede a Grafana
   - Haz clic en "+" > "Import"
   - Sube el archivo JSON que creaste
   - Haz clic en "Import"

## 3. Verificación de Funcionamiento

1. **Verifica que los datos se estén recibiendo en Grafana**:
   - Una vez que Locust está enviando datos, deberías ver cómo se actualizan los paneles en Grafana
   - Si no ves datos, verifica que los consumidores estén procesando los mensajes correctamente
   - Confirma que los nombres de las claves en Valkey coincidan con los que usas en las consultas de Grafana

2. **Ajusta el dashboard según sea necesario**:
   - Puedes modificar los paneles, agregar más o cambiar la disposición según tus preferencias
   - Asegúrate de mantener la gráfica de barras para "Total de reportes por condición climática" que es obligatoria según el enunciado

## 4. Solución de Problemas Comunes

- **No se muestran datos en Grafana**: 
  - Verifica que los consumidores estén guardando los datos correctamente en Valkey
  - Confirma que las claves usadas en Grafana coincidan con las que generan los consumidores

- **Error de conexión a Valkey**: 
  - Verifica que el datasource de Valkey esté correctamente configurado en Grafana
  - Prueba con el comando `kubectl port-forward` si es necesario para acceder directamente

- **Errores en las simulaciones de Locust**: 
  - Verifica que la API de Rust esté recibiendo correctamente las peticiones
  - Confirma que la estructura de los datos enviados coincida con lo que espera la API