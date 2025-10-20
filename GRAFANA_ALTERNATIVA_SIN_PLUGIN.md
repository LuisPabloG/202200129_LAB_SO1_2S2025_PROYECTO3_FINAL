# Guía para Configurar Grafana sin el Plugin de Redis

Si no puedes instalar el plugin de Redis en Grafana, podemos usar una solución alternativa usando el plugin SimpleJson que viene pre-instalado.

## 1. Crear un Proxy para acceder a Valkey

Primero, necesitamos crear un servicio intermediario que exponga los datos de Valkey a través de una API REST.

1. **Crea un archivo para el servicio proxy**:
```bash
touch ~/202200129_LAB_SO1_2S2025_PROYECTO3_FINAL/valkey-proxy.py
```

2. **Añade este código al archivo**:
```python
#!/usr/bin/env python3
from flask import Flask, jsonify, request
import redis
import os
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Habilitar CORS para todas las rutas

# Configuración de conexión a Valkey/Redis
REDIS_HOST = os.getenv('REDIS_HOST', 'valkey-service')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')

# Crear una conexión a Redis
redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    password=REDIS_PASSWORD,
    decode_responses=True
)

@app.route('/')
def hello():
    return jsonify({"status": "Valkey Proxy is running"})

@app.route('/search', methods=['POST'])
def search():
    # Para Grafana SimpleJson datasource
    return jsonify(["sunny", "cloudy", "rainy", "foggy", "temperature", "humidity"])

@app.route('/query', methods=['POST'])
def query():
    req_data = request.get_json()
    result = []
    
    for target in req_data.get('targets', []):
        target_type = target.get('type', 'timeserie')
        target_name = target.get('target', '')
        
        # Para obtener los datos de municipios para clima
        if target_name in ['sunny', 'cloudy', 'rainy', 'foggy']:
            # Determinar el municipio según el carnet (último dígito)
            carnet = "202200129"  # Cambia por tu carnet
            last_digit = int(carnet[-1])
            
            if last_digit in [0, 1, 2]:
                municipio = "mixco"
            elif last_digit in [3, 4, 5]:
                municipio = "guatemala"
            elif last_digit in [6, 7]:
                municipio = "amatitlan"
            else:  # 8, 9
                municipio = "chinautla"
            
            # Obtener el valor de la clave específica
            key = f"{target_name}_{municipio}"
            value = redis_client.get(key)
            
            if value is None:
                value = "0"  # Valor por defecto si no existe
            
            try:
                value = int(value)
            except:
                value = 0
            
            # Formato para gráfico de barras
            result.append({
                "target": target_name.capitalize(),
                "datapoints": [[value, int(os.time() * 1000)]]
            })
        
        # Para temperatura y humedad
        elif target_name in ['temperature', 'humidity']:
            # Determinar el municipio según el carnet
            carnet = "202200129"  # Cambia por tu carnet
            last_digit = int(carnet[-1])
            
            if last_digit in [0, 1, 2]:
                municipio = "mixco"
            elif last_digit in [3, 4, 5]:
                municipio = "guatemala"
            elif last_digit in [6, 7]:
                municipio = "amatitlan"
            else:  # 8, 9
                municipio = "chinautla"
            
            # Obtener el valor
            key = f"{target_name}_{municipio}"
            value = redis_client.get(key)
            
            if value is None:
                value = "0"  # Valor por defecto si no existe
            
            try:
                value = float(value)
            except:
                value = 0
            
            # Formato para gauge/stat
            result.append({
                "target": target_name.capitalize(),
                "datapoints": [[value, int(os.time() * 1000)]]
            })
    
    return jsonify(result)

@app.route('/annotations', methods=['POST'])
def annotations():
    # Para Grafana SimpleJson datasource (no usado pero requerido)
    return jsonify([])

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3001)
```

3. **Crea un Dockerfile para el proxy**:
```bash
touch ~/202200129_LAB_SO1_2S2025_PROYECTO3_FINAL/Dockerfile.valkey-proxy
```

4. **Añade este contenido al Dockerfile**:
```Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY valkey-proxy.py /app/

RUN pip install flask redis flask-cors

EXPOSE 3001

CMD ["python", "valkey-proxy.py"]
```

## 2. Construir y desplegar el Proxy

1. **Construye la imagen Docker**:
```bash
cd ~/202200129_LAB_SO1_2S2025_PROYECTO3_FINAL
docker build -f Dockerfile.valkey-proxy -t valkey-proxy:latest .
```

2. **Etiqueta la imagen para tu registry (Zot)**:
```bash
docker tag valkey-proxy:latest <tu-ip-zot>:5000/valkey-proxy:latest
```

3. **Sube la imagen a tu registry**:
```bash
docker push <tu-ip-zot>:5000/valkey-proxy:latest
```

4. **Crea un archivo YAML para el despliegue**:
```bash
touch ~/202200129_LAB_SO1_2S2025_PROYECTO3_FINAL/valkey-proxy-deployment.yaml
```

5. **Añade este contenido al YAML**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: valkey-proxy
  labels:
    app: valkey-proxy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: valkey-proxy
  template:
    metadata:
      labels:
        app: valkey-proxy
    spec:
      containers:
      - name: valkey-proxy
        image: <tu-ip-zot>:5000/valkey-proxy:latest
        ports:
        - containerPort: 3001
        env:
        - name: REDIS_HOST
          value: "valkey-service"
        - name: REDIS_PORT
          value: "6379"
---
apiVersion: v1
kind: Service
metadata:
  name: valkey-proxy-service
spec:
  selector:
    app: valkey-proxy
  ports:
  - port: 3001
    targetPort: 3001
  type: LoadBalancer
```

6. **Despliega el proxy en Kubernetes**:
```bash
kubectl apply -f valkey-proxy-deployment.yaml
```

7. **Espera a que se asigne una IP externa**:
```bash
kubectl get svc valkey-proxy-service --watch
```

## 3. Configura Grafana con el Datasource SimpleJSON

1. **Accede a Grafana**:
   - URL: http://104.198.150.238:3000
   - Usuario: admin
   - Contraseña: admin

2. **Agrega un nuevo datasource**:
   - Ve a Configuración (⚙️) → Data sources
   - Haz clic en "Add data source"
   - Busca y selecciona "SimpleJson"

3. **Configura el datasource**:
   - Name: ValkeySJ (o cualquier nombre descriptivo)
   - URL: `http://<IP-EXTERNA-VALKEY-PROXY>:3001` (la IP que obtuviste del servicio valkey-proxy-service)
   - Access: Server (default)
   - Deja las demás opciones con sus valores predeterminados
   - Haz clic en "Save & Test"

## 4. Crea un Nuevo Dashboard Usando SimpleJSON

1. **Crea un nuevo dashboard**:
   - Haz clic en "+" en el menú lateral izquierdo
   - Selecciona "Dashboard"
   - Haz clic en "Add visualization"

2. **Configura un panel para el Total de Reportes por Condición Climática**:
   - Datasource: ValkeySJ (o el nombre que elegiste)
   - Tipo de panel: Bar chart
   - Queries:
     * A: target = sunny
     * B: target = cloudy
     * C: target = rainy
     * D: target = foggy
   - Haz clic en "Apply"

3. **Configura un panel para la Temperatura**:
   - Haz clic en "Add panel"
   - Datasource: ValkeySJ
   - Tipo de panel: Gauge
   - Query: target = temperature
   - En Field: Standard options → Unit: selecciona Temperature → Celsius
   - Haz clic en "Apply"

4. **Configura un panel para la Humedad**:
   - Haz clic en "Add panel"
   - Datasource: ValkeySJ
   - Tipo de panel: Gauge
   - Query: target = humidity
   - En Field: Standard options → Unit: selecciona Misc → percent (0-100)
   - Haz clic en "Apply"

5. **Guarda el dashboard**:
   - Haz clic en el ícono de guardar en la parte superior derecha
   - Asigna un nombre como "Weather Tweets Dashboard - <TU_CARNET>"
   - Haz clic en "Save"

## 5. Prueba el Dashboard

1. **Genera datos con Locust** según las instrucciones anteriores

2. **Configura la actualización automática**:
   - En la parte superior derecha del dashboard, selecciona un intervalo de actualización de 5s

3. **Verifica que los datos se muestren correctamente** a medida que Locust envía tweets del clima