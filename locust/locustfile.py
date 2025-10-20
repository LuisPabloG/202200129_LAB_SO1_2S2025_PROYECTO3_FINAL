from locust import HttpUser, task, between
import random
import json

class WeatherTweetUser(HttpUser):
    wait_time = between(0.1, 0.5)
    
    municipalities = ["mixco", "guatemala", "amatitlan", "chinautla"]
    weathers = ["sunny", "cloudy", "rainy", "foggy"]
    
    @task
    def send_weather_tweet(self):
        # Generar datos aleatorios
        tweet = {
            "municipality": random.choice(self.municipalities),
            "temperature": random.randint(-5, 40),
            "humidity": random.randint(0, 100),
            "weather": random.choice(self.weathers)
        }
        
        # Enviar POST request
        with self.client.post(
            "/api/tweet",
            json=tweet,
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed with status code: {response.status_code}")
    
    @task(1)
    def health_check(self):
        self.client.get("/health")
