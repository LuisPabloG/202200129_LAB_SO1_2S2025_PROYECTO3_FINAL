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