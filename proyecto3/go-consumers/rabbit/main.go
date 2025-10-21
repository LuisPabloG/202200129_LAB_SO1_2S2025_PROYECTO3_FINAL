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

	"github.com/go-redis/redis/v8"
	"github.com/streadway/amqp"
)

type WeatherTweet struct {
	Municipality string `json:"municipality"`
	Temperature  int    `json:"temperature"`
	Humidity     int    `json:"humidity"`
	Weather      string `json:"weather"`
}

func failOnError(err error, msg string) {
	if err != nil {
		log.Fatalf("%s: %s", msg, err)
	}
}

func main() {
	// Configuración de RabbitMQ
	rabbitURL := os.Getenv("RABBIT_URL")
	if rabbitURL == "" {
		rabbitURL = "amqp://guest:guest@rabbitmq:5672/"
	}

	queueName := os.Getenv("RABBIT_QUEUE")
	if queueName == "" {
		queueName = "weather-tweets"
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

	// Conectar a RabbitMQ
	conn, err := amqp.Dial(rabbitURL)
	failOnError(err, "Failed to connect to RabbitMQ")
	defer conn.Close()

	ch, err := conn.Channel()
	failOnError(err, "Failed to open a channel")
	defer ch.Close()

	// Declarar la cola
	q, err := ch.QueueDeclare(
		queueName, // name
		true,      // durable
		false,     // delete when unused
		false,     // exclusive
		false,     // no-wait
		nil,       // arguments
	)
	failOnError(err, "Failed to declare a queue")

	// Configurar QoS
	err = ch.Qos(
		1,     // prefetch count
		0,     // prefetch size
		false, // global
	)
	failOnError(err, "Failed to set QoS")

	// Consumir mensajes
	msgs, err := ch.Consume(
		q.Name, // queue
		"",     // consumer
		false,  // auto-ack
		false,  // exclusive
		false,  // no-local
		false,  // no-wait
		nil,    // args
	)
	failOnError(err, "Failed to register a consumer")

	log.Printf("Starting RabbitMQ consumer for queue: %s", q.Name)

	// Manejo de señales para cierre limpio
	sigchan := make(chan os.Signal, 1)
	signal.Notify(sigchan, syscall.SIGINT, syscall.SIGTERM)

	// Canal para notificar terminación
	done := make(chan bool)

	// Procesar mensajes
	go func() {
		for msg := range msgs {
			log.Printf("Received message: %s", string(msg.Body))

			var tweet WeatherTweet
			if err := json.Unmarshal(msg.Body, &tweet); err != nil {
				log.Printf("Error unmarshaling message: %v", err)
				msg.Ack(false)
				continue
			}

			// Procesar el tweet y almacenar en Valkey/Redis
			if err := processTweet(ctx, rdb, &tweet); err != nil {
				log.Printf("Error processing tweet: %v", err)
				msg.Nack(false, true) // Requeue message on error
			} else {
				msg.Ack(false)
			}
		}
		done <- true
	}()

	// Esperar señal de terminación
	select {
	case sig := <-sigchan:
		log.Printf("Caught signal %v: terminating", sig)
	case <-done:
		log.Println("Channel closed")
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
