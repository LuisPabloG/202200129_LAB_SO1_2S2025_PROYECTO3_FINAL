#!/usr/bin/env python3
from flask import Flask, jsonify, request
import redis
import time
from flask_cors import CORS
import os

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
                "datapoints": [[value, int(time.time() * 1000)]]
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
                "datapoints": [[value, int(time.time() * 1000)]]
            })
    
    return jsonify(result)

@app.route('/annotations', methods=['POST'])
def annotations():
    # Para Grafana SimpleJson datasource (no usado pero requerido)
    return jsonify([])

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3001)