# Configuración del Dashboard de Grafana con Redis/Valkey

Este documento explica cómo configurar correctamente el datasource de Redis/Valkey y crear un dashboard para visualizar los tweets del clima generados por Locust.

## 1. Configuración del Datasource Redis

Veo que ya has instalado y configurado el datasource de Redis con estos parámetros:
- **Nombre**: Valkey
- **Tipo**: Redis (Standalone)
- **Dirección**: redis://...

Para que funcione correctamente con tu sistema, asegúrate de que la dirección sea la correcta:

1. **Dirección correcta para el servicio Valkey**:
   - Si estás usando port-forwarding: `redis://localhost:6379`
   - Si estás accediendo directamente al servicio en Kubernetes: `redis://valkey-service:6379`
   - Si tienes un servicio con otro nombre: `redis://<nombre-servicio>:6379`

2. **Si el servicio tiene contraseña**, asegúrate de incluirla en el campo correspondiente.

3. **Haz clic en "Save & Test"** para verificar la conexión.

## 2. Verificación de Claves en Valkey

Antes de configurar el dashboard, vamos a verificar qué claves existen en Valkey:

1. **Ve a la sección "CLI"** del datasource Redis (hay un botón "CLI" junto a "Settings").

2. **Ejecuta el comando para ver las claves existentes**:
   ```
   KEYS *
   ```

3. **Busca claves relacionadas con los tweets del clima**, que deberían seguir este patrón:
   - `sunny_<municipio>`: conteo de tweets con clima soleado
   - `cloudy_<municipio>`: conteo de tweets con clima nublado
   - `rainy_<municipio>`: conteo de tweets con clima lluvioso
   - `foggy_<municipio>`: conteo de tweets con clima neblinoso
   - `temperature_<municipio>`: temperatura promedio
   - `humidity_<municipio>`: humedad promedio

   Donde `<municipio>` es uno de: mixco, guatemala, amatitlan, chinautla (según el último dígito de tu carnet).

## 3. Creación del Dashboard

### 3.1 Panel para "Total de reportes por condición climática"

1. **Crea un nuevo dashboard**: Haz clic en "+" → "Dashboard"

2. **Añade un nuevo panel**: Haz clic en "Add panel" → "Add a new panel"

3. **Configura el tipo de visualización**:
   - Selecciona "Bar chart" en el menú desplegable de la derecha

4. **Configura las consultas (asumiendo que tu municipio es chinautla - último dígito 9)**:
   - Query A:
     * Command: GET
     * Key: sunny_chinautla
     * Legend: Soleado
   - Query B:
     * Command: GET
     * Key: cloudy_chinautla
     * Legend: Nublado
   - Query C:
     * Command: GET
     * Key: rainy_chinautla
     * Legend: Lluvioso
   - Query D:
     * Command: GET
     * Key: foggy_chinautla
     * Legend: Neblinoso

5. **Configura el título del panel**: "Total de reportes por condición climática"

6. **Haz clic en "Apply"** para guardar el panel

### 3.2 Panel para "Temperatura Promedio"

1. **Añade otro panel**: Haz clic en "Add panel" → "Add a new panel"

2. **Configura el tipo de visualización**:
   - Selecciona "Gauge" o "Stat" en el menú desplegable

3. **Configura la consulta**:
   - Command: GET
   - Key: temperature_chinautla
   - Legend: Temperatura

4. **Configura las unidades**:
   - En la pestaña "Field", encuentra "Standard options" → "Unit"
   - Selecciona "Temperature" → "Celsius" (°C)

5. **Configura umbrales de color** (opcional):
   - En "Standard options" → "Thresholds", configura:
     * 0 a 15: Azul
     * 15 a 25: Verde
     * 25 a 30: Amarillo
     * >30: Rojo

6. **Configura el título**: "Temperatura Promedio"

7. **Haz clic en "Apply"** para guardar

### 3.3 Panel para "Humedad Promedio"

1. **Añade otro panel**: Haz clic en "Add panel" → "Add a new panel"

2. **Configura el tipo de visualización**:
   - Selecciona "Gauge" en el menú desplegable

3. **Configura la consulta**:
   - Command: GET
   - Key: humidity_chinautla
   - Legend: Humedad

4. **Configura las unidades**:
   - En la pestaña "Field", encuentra "Standard options" → "Unit"
   - Selecciona "Misc" → "percent (0-100)"
   - En "Min" pon 0 y en "Max" pon 100

5. **Configura umbrales de color**:
   - 0 a 30: Verde (seco)
   - 30 a 60: Azul (normal)
   - 60 a 80: Amarillo (húmedo)
   - >80: Rojo (muy húmedo)

6. **Configura el título**: "Humedad Promedio"

7. **Haz clic en "Apply"** para guardar

## 4. Configuración final del Dashboard

1. **Organiza los paneles**: Puedes arrastrar y redimensionar los paneles para crear un diseño atractivo

2. **Configura la actualización automática**:
   - En la parte superior derecha, junto al selector de rango de tiempo, selecciona el ícono de actualización
   - Establece un intervalo de actualización (por ejemplo, cada 5 segundos)

3. **Guarda el dashboard**:
   - Haz clic en el icono de guardar (disquete) en la parte superior derecha
   - Asigna un nombre como "Weather Tweets Dashboard - 202200129"
   - Haz clic en "Save"

## 5. Prueba con datos generados por Locust

1. **Inicia Locust** para generar tweets del clima:
   ```bash
   ./run-locust-cloudshell.sh
   ```

2. **Configura Locust**:
   - Número de usuarios: 10
   - Tasa de generación: 10/segundo
   - Host: http://104.198.150.238 (o la IP de tu Ingress)
   - Inicia la prueba

3. **Observa el dashboard** para ver cómo se actualizan los datos en tiempo real

## Notas importantes:

- Si no ves datos en el dashboard, verifica que los consumidores estén procesando correctamente los mensajes de Kafka/RabbitMQ y guardando los datos en Valkey
- Asegúrate de que las claves en Valkey coincidan exactamente con las que usas en las consultas de Grafana
- Si cambias el municipio en el archivo `locustfile.py`, asegúrate de actualizar también las consultas en Grafana para que usen el mismo municipio