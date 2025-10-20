package main

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/streadway/amqp"
)

const (
	rabbitMQURL   = "amqp://guest:guest@rabbitmq:5672/"
	rabbitMQQueue = "weather_queue"
	valkeyAddr    = "valkey:6379"
)

// Estructura para el mensaje de weather tweet
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

	// Conectar a RabbitMQ
	conn, err := amqp.Dial(rabbitMQURL)
	failOnError(err, "Failed to connect to RabbitMQ")
	defer conn.Close()

	ch, err := conn.Channel()
	failOnError(err, "Failed to open a channel")
	defer ch.Close()

	// Declarar la cola
	q, err := ch.QueueDeclare(
		rabbitMQQueue, // nombre
		false,         // durable
		false,         // eliminar cuando no esté en uso
		false,         // exclusiva
		false,         // no-espera
		nil,           // argumentos
	)
	failOnError(err, "Failed to declare a queue")

	// Configurar QoS
	err = ch.Qos(
		1,     // prefetch count
		0,     // prefetch size
		false, // global
	)
	failOnError(err, "Failed to set QoS")

	// Registrar consumidor
	msgs, err := ch.Consume(
		q.Name, // cola
		"",     // consumidor
		false,  // auto-ack
		false,  // exclusivo
		false,  // no-local
		false,  // no-espera
		nil,    // argumentos
	)
	failOnError(err, "Failed to register a consumer")

	log.Println("Consumidor RabbitMQ iniciado, esperando mensajes...")

	// Bucle principal de consumo
	for msg := range msgs {
		log.Printf("Mensaje recibido de RabbitMQ: %s", string(msg.Body))

		// Parsear el mensaje JSON
		var tweet WeatherTweet
		if err := json.Unmarshal(msg.Body, &tweet); err != nil {
			log.Printf("Error parseando JSON: %v", err)
			msg.Nack(false, false) // rechazar mensaje
			continue
		}

		// Verificar si el municipio es chinautla (basado en tu carnet 202200129)
		if tweet.Municipality == "chinautla" {
			// Incrementar contador para la condición climática en chinautla
			weatherKey := "weather_count_" + tweet.Weather
			err := rdb.Incr(ctx, weatherKey).Err()
			if err != nil {
				log.Printf("Error incrementando contador en Valkey: %v", err)
				msg.Nack(false, true) // rechazar y reencolar
				continue
			}

			// También guardar el tweet completo (con una expiración de 1 hora)
			tweetKey := "tweet_rabbit_" + time.Now().Format("20060102150405") + "_" + tweet.Municipality
			tweetJSON, _ := json.Marshal(tweet)
			err = rdb.Set(ctx, tweetKey, string(tweetJSON), 1*time.Hour).Err()
			if err != nil {
				log.Printf("Error guardando tweet en Valkey: %v", err)
				msg.Nack(false, true) // rechazar y reencolar
				continue
			}

			log.Printf("Datos de %s procesados y guardados en Valkey desde RabbitMQ", tweet.Municipality)
		} else {
			log.Printf("Ignorando municipio %s (no es chinautla)", tweet.Municipality)
		}

		// Confirmar procesamiento
		msg.Ack(false)
	}

	log.Println("Consumidor RabbitMQ finalizado")
}
