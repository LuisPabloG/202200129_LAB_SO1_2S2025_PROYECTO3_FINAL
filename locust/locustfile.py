from locust import HttpUser, task, between
import random
import json

# Definir municipios y climas posibles según el enunciado
MUNICIPALITIES = ["mixco", "guatemala", "amatitlan", "chinautla"]
WEATHERS = ["sunny", "cloudy", "rainy", "foggy"]

class WeatherTweetUser(HttpUser):
    wait_time = between(1, 3)  # Tiempo entre peticiones (1-3 segundos)
    
    @task
    def post_weather_tweet(self):
        # Construir un tweet aleatorio
        tweet = {
            "municipality": random.choice(MUNICIPALITIES),
            "temperature": random.randint(15, 35),  # Temperatura entre 15-35°C
            "humidity": random.randint(30, 90),     # Humedad entre 30-90%
            "weather": random.choice(WEATHERS)
        }
        
        # Enviar el tweet a la API
        headers = {'Content-Type': 'application/json'}
        self.client.post("/tweet", data=json.dumps(tweet), headers=headers)