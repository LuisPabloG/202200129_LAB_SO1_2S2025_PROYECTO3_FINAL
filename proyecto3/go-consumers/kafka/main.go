package main

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/confluentinc/confluent-kafka-go/v2/kafka"
	"github.com/go-redis/redis/v8"
)

type WeatherTweet struct {
	Municipality string `json:"municipality"`
	Temperature  int    `json:"temperature"`
	Humidity     int    `json:"humidity"`
	Weather      string `json:"weather"`
}

func main() {
	// Configuración de Kafka
	brokers := os.Getenv("KAFKA_BROKERS")
	if brokers == "" {
		brokers = "kafka:9092"
	}

	topic := os.Getenv("KAFKA_TOPIC")
	if topic == "" {
		topic = "weather-tweets"
	}

	group := os.Getenv("KAFKA_GROUP")
	if group == "" {
		group = "weather-consumer-group"
	}

	// Configuración de Valkey (Redis compatible)
	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "valkey:6379"
	}

	redisPassword := os.Getenv("REDIS_PASSWORD")
	redisDB := 0
	if dbStr := os.Getenv("REDIS_DB"); dbStr != "" {
		var err error
		redisDB, err = strconv.Atoi(dbStr)
		if err != nil {
			log.Printf("Invalid REDIS_DB value, using default 0: %v", err)
			redisDB = 0
		}
	}

	// Crear cliente Valkey/Redis
	rdb := redis.NewClient(&redis.Options{
		Addr:     redisAddr,
		Password: redisPassword,
		DB:       redisDB,
	})

	ctx := context.Background()

	// Verificar conexión a Valkey/Redis
	_, err := rdb.Ping(ctx).Result()
	if err != nil {
		log.Fatalf("Failed to connect to Valkey: %v", err)
	}
	log.Println("Connected to Valkey successfully")

	// Crear consumidor de Kafka
	c, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers":  brokers,
		"group.id":           group,
		"auto.offset.reset":  "earliest",
		"enable.auto.commit": "true",
	})
	if err != nil {
		log.Fatalf("Failed to create Kafka consumer: %v", err)
	}
	defer c.Close()

	// Suscribirse al tema
	err = c.SubscribeTopics([]string{topic}, nil)
	if err != nil {
		log.Fatalf("Failed to subscribe to topic %s: %v", topic, err)
	}
	log.Printf("Subscribed to Kafka topic: %s", topic)

	// Manejo de señales para cierre limpio
	sigchan := make(chan os.Signal, 1)
	signal.Notify(sigchan, syscall.SIGINT, syscall.SIGTERM)

	// Procesar mensajes
	run := true
	for run {
		select {
		case sig := <-sigchan:
			log.Printf("Caught signal %v: terminating", sig)
			run = false
		default:
			ev := c.Poll(100)
			if ev == nil {
				continue
			}

			switch e := ev.(type) {
			case *kafka.Message:
				log.Printf("Received message: %s", string(e.Value))

				var tweet WeatherTweet
				if err := json.Unmarshal(e.Value, &tweet); err != nil {
					log.Printf("Error unmarshaling message: %v", err)
					continue
				}

				// Procesar el tweet y almacenar en Valkey/Redis
				if err := processTweet(ctx, rdb, &tweet); err != nil {
					log.Printf("Error processing tweet: %v", err)
				}

			case kafka.Error:
				log.Printf("Error: %v", e)
				if e.Code() == kafka.ErrAllBrokersDown {
					run = false
				}
			default:
				log.Printf("Ignored event: %v", e)
			}
		}
	}
}

func processTweet(ctx context.Context, rdb *redis.Client, tweet *WeatherTweet) error {
	log.Printf("Processing tweet: %+v", tweet)

	// Incrementar contador por municipio
	municipalityKey := "municipality:" + tweet.Municipality
	if err := rdb.Incr(ctx, municipalityKey).Err(); err != nil {
		return err
	}

	// Incrementar contador por clima
	weatherKey := "weather:" + tweet.Weather
	if err := rdb.Incr(ctx, weatherKey).Err(); err != nil {
		return err
	}

	// Almacenar los datos del tweet (con TTL para evitar saturación)
	tweetID := time.Now().UnixNano()
	tweetKey := "tweet:" + strconv.FormatInt(tweetID, 10)

	// Serializar el tweet a JSON
	tweetJSON, err := json.Marshal(tweet)
	if err != nil {
		return err
	}

	// Almacenar con un TTL de 1 hora (3600 segundos)
	if err := rdb.Set(ctx, tweetKey, tweetJSON, 3600*time.Second).Err(); err != nil {
		return err
	}

	// Actualizar temperatura promedio y humedad para el municipio
	// Agregamos el valor actual al conjunto para calcular después
	tempKey := "temperature:" + tweet.Municipality
	humidityKey := "humidity:" + tweet.Municipality

	pipe := rdb.Pipeline()
	pipe.RPush(ctx, tempKey, tweet.Temperature)
	pipe.RPush(ctx, humidityKey, tweet.Humidity)
	pipe.Expire(ctx, tempKey, 24*time.Hour) // TTL de 24 horas
	pipe.Expire(ctx, humidityKey, 24*time.Hour)
	_, err = pipe.Exec(ctx)

	return err
}
