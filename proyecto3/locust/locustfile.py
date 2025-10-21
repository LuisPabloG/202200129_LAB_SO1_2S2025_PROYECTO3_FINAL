from locust import HttpUser, task, between
import random
import json

class WeatherTweetUser(HttpUser):
    wait_time = between(1, 5)  # Tiempo entre solicitudes (1-5 segundos)

    municipalities = ["mixco", "guatemala", "amatitlan", "chinautla"]
    weathers = ["sunny", "cloudy", "rainy", "foggy"]

    @task
    def send_weather_tweet(self):
        # Generar datos aleatorios para el tweet
        tweet = {
            "municipality": "chinautla",  # Carnet 202200129 - último dígito 9 => chinautla
            "temperature": random.randint(10, 35),  # Temperatura entre 10°C y 35°C
            "humidity": random.randint(30, 95),     # Humedad entre 30% y 95%
            "weather": random.choice(self.weathers)  # Clima aleatorio
        }

        # Enviar el tweet a la API
        headers = {'Content-Type': 'application/json'}
        response = self.client.post("/tweet", json=tweet, headers=headers)
        
        # Log de la respuesta
        if response.status_code == 200:
            print(f"Tweet sent successfully: {tweet}")
        else:
            print(f"Error sending tweet: {response.status_code} - {response.text}")

    @task(3)  # Proporción 3:1 respecto a send_weather_tweet
    def send_chinautla_tweet(self):
        # Generar datos específicos para chinautla (último dígito del carnet 9)
        tweet = {
            "municipality": "chinautla",
            "temperature": random.randint(10, 35),
            "humidity": random.randint(30, 95),
            "weather": random.choice(self.weathers)
        }

        # Enviar el tweet a la API
        headers = {'Content-Type': 'application/json'}
        response = self.client.post("/tweet", json=tweet, headers=headers)
        
        # Log de la respuesta
        if response.status_code == 200:
            print(f"Chinautla tweet sent successfully: {tweet}")
        else:
            print(f"Error sending Chinautla tweet: {response.status_code} - {response.text}")