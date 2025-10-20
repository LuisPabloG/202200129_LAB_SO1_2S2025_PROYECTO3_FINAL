package main

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/segmentio/kafka-go"
)

const (
	kafkaTopic   = "weather-tweets"
	kafkaGroupID = "weather-consumer-group"
	kafkaAddr    = "kafka:9092"
	valkeyAddr   = "valkey:6379"
)

// Estructura para el mensaje de weather tweet
type WeatherTweet struct {
	Municipality string `json:"municipality"`
	Temperature  int    `json:"temperature"`
	Humidity     int    `json:"humidity"`
	Weather      string `json:"weather"`
}

func main() {
	// Conectar a Valkey (Redis)
	ctx := context.Background()
	rdb := redis.NewClient(&redis.Options{
		Addr:     valkeyAddr,
		Password: "", // sin contraseña
		DB:       0,  // base de datos por defecto
	})

	// Verificar conexión a Valkey
	_, err := rdb.Ping(ctx).Result()
	if err != nil {
		log.Fatalf("Error conectando a Valkey: %v", err)
	}
	log.Println("Conectado a Valkey")

	// Configurar el lector de Kafka
	reader := kafka.NewReader(kafka.ReaderConfig{
		Brokers:   []string{kafkaAddr},
		Topic:     kafkaTopic,
		GroupID:   kafkaGroupID,
		MinBytes:  10e3, // 10KB
		MaxBytes:  10e6, // 10MB
		MaxWait:   500 * time.Millisecond,
		Partition: 0,
	})

	defer reader.Close()

	log.Println("Consumidor Kafka iniciado, esperando mensajes...")

	// Bucle principal de consumo
	for {
		m, err := reader.ReadMessage(context.Background())
		if err != nil {
			log.Printf("Error leyendo mensaje: %v", err)
			continue
		}

		log.Printf("Mensaje recibido de Kafka: %s", string(m.Value))

		// Parsear el mensaje JSON
		var tweet WeatherTweet
		if err := json.Unmarshal(m.Value, &tweet); err != nil {
			log.Printf("Error parseando JSON: %v", err)
			continue
		}

		// Verificar si el municipio es chinautla (basado en tu carnet 202200129)
		if tweet.Municipality == "chinautla" {
			// Incrementar contador para la condición climática en chinautla
			weatherKey := "weather_count_" + tweet.Weather
			err := rdb.Incr(ctx, weatherKey).Err()
			if err != nil {
				log.Printf("Error incrementando contador en Valkey: %v", err)
				continue
			}

			// También guardar el tweet completo (con una expiración de 1 hora)
			tweetKey := "tweet_kafka_" + time.Now().Format("20060102150405") + "_" + tweet.Municipality
			tweetJSON, _ := json.Marshal(tweet)
			err = rdb.Set(ctx, tweetKey, string(tweetJSON), 1*time.Hour).Err()
			if err != nil {
				log.Printf("Error guardando tweet en Valkey: %v", err)
			}

			log.Printf("Datos de %s procesados y guardados en Valkey desde Kafka", tweet.Municipality)
		} else {
			log.Printf("Ignorando municipio %s (no es chinautla)", tweet.Municipality)
		}
	}
}
