# Guía para Configurar el Dashboard de Grafana

Esta guía te muestra cómo configurar paso a paso tu dashboard de Grafana para visualizar los tweets del clima, según los requerimientos del proyecto.

## 1. Acceder a Grafana

1. **Abre Grafana en tu navegador**:
   - URL: http://104.198.150.238:3000
   - Usuario: admin
   - Contraseña: admin

## 2. Configurar la Fuente de Datos (Redis/Valkey)

1. **Agrega una nueva fuente de datos**:
   - Haz clic en el ícono ⚙️ (Configuración) en el menú lateral izquierdo
   - Selecciona "Data sources"
   - Haz clic en "Add data source"
   - Busca y selecciona "Redis" (esta fuente de datos funciona para Valkey)

2. **Configura la conexión a Valkey**:
   - Name: Valkey (o cualquier nombre descriptivo)
   - URL/Address: `valkey-service` (el nombre del servicio de Valkey en Kubernetes)
   - Port: `6379` (puerto por defecto de Redis/Valkey)
   - Deja el resto de opciones con sus valores predeterminados
   - Haz clic en "Save & Test" para verificar la conexión

## 3. Importar el Dashboard Predefinido

1. **Importa el dashboard JSON**:
   - Haz clic en el icono "+" en el menú lateral izquierdo
   - Selecciona "Import"
   - Haz clic en "Upload JSON file"
   - Selecciona el archivo `dashboard-grafana.json` de tu proyecto
   - En la siguiente pantalla, selecciona la fuente de datos "Valkey" (o el nombre que hayas elegido)
   - Haz clic en "Import"

## 4. Ajustar el Dashboard para tu Carnet

El dashboard está configurado para el municipio según el último dígito del carnet 202200129 (chinautla). 
Si necesitas cambiarlo para tu carnet:

1. **Determina tu municipio según tu carnet**:
   - Último dígito 0, 1, 2: mixco
   - Último dígito 3, 4, 5: guatemala
   - Último dígito 6, 7: amatitlan
   - Último dígito 8, 9: chinautla

2. **Edita cada panel del dashboard**:
   - Haz clic en el título del panel
   - Selecciona "Edit"
   - En la pestaña "Query", actualiza cada consulta para usar tu municipio
   - Por ejemplo, cambia `sunny_chinautla` por `sunny_mixco` si corresponde
   - Guarda los cambios

## 5. Verificar Datos con Locust

1. **Genera datos con Locust**:
   - Ejecuta Locust y configura una prueba con 10 usuarios y tasa de 10/segundo
   - Inicia la prueba para generar tweets del clima
   - Deja que se ejecute por un tiempo para generar suficientes datos

2. **Verifica el dashboard**:
   - Regresa a Grafana y verifica que los datos comiencen a aparecer
   - Si no aparecen datos después de un tiempo, verifica:
     - Que los consumidores estén procesando los mensajes correctamente
     - Que las claves en Valkey coincidan con las utilizadas en el dashboard
     - Que la conexión a la fuente de datos esté funcionando

## 6. Personalizar el Dashboard (Opcional)

Si deseas personalizar más el dashboard:

1. **Ajusta el título**:
   - Haz clic en el icono de engranaje ⚙️ en la parte superior derecha del dashboard
   - Actualiza el título y la descripción con tu carnet

2. **Modifica los paneles**:
   - Puedes cambiar colores, rangos, unidades, etc.
   - Ajusta el diseño arrastrando y redimensionando los paneles

3. **Añade nuevos paneles**:
   - Haz clic en "Add panel" para agregar visualizaciones adicionales

4. **Configura la actualización automática**:
   - Ajusta el tiempo de actualización automática en la parte superior derecha
   - Recomendado: 5s o 10s para ver los cambios en tiempo real

## 7. Guardar y Compartir

1. **Guarda tus cambios**:
   - Haz clic en el icono de guardar 💾 en la parte superior derecha
   - Asigna un nombre claro que incluya tu carnet

2. **Configura como dashboard por defecto** (opcional):
   - Haz clic en el icono ⭐ para marcarlo como favorito
   - Ve a Configuración > Preferences > Home Dashboard y selecciona tu dashboard