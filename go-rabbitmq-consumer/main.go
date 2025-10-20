package main

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/streadway/amqp"
	"github.com/redis/go-redis/v9"
)

type WeatherData struct {
	Municipality string `json:"municipality"`
	Temperature  int32  `json:"temperature"`
	Humidity     int32  `json:"humidity"`
	Weather      string `json:"weather"`
}

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

func connectRabbitMQ(url string) (*amqp.Connection, *amqp.Channel, error) {
	var conn *amqp.Connection
	var err error

	for i := 0; i < 10; i++ {
		conn, err = amqp.Dial(url)
		if err == nil {
			break
		}
		log.Printf("Failed to connect to RabbitMQ (attempt %d): %v", i+1, err)
		time.Sleep(5 * time.Second)
	}

	if err != nil {
		return nil, nil, err
	}

	channel, err := conn.Channel()
	if err != nil {
		return nil, nil, err
	}

	return conn, channel, nil
}

func main() {
	rabbitmqURL := getEnv("RABBITMQ_URL", "amqp://guest:guest@rabbitmq-service:5672/")
	queueName := getEnv("RABBITMQ_QUEUE", "weather-tweets")
	valkeyAddr := getEnv("VALKEY_ADDR", "valkey-service:6379")

	// Conectar a RabbitMQ
	conn, channel, err := connectRabbitMQ(rabbitmqURL)
	if err != nil {
		log.Fatalf("Failed to connect to RabbitMQ: %v", err)
	}
	defer conn.Close()
	defer channel.Close()

	_, err = channel.QueueDeclare(
		queueName,
		true,  // durable
		false, // delete when unused
		false, // exclusive
		false, // no-wait
		nil,   // arguments
	)
	if err != nil {
		log.Fatalf("Failed to declare queue: %v", err)
	}

	log.Printf("Connected to RabbitMQ, queue: %s", queueName)

	// Configurar Valkey Client
	valkeyClient := redis.NewClient(&redis.Options{
		Addr:     valkeyAddr,
		Password: "",
		DB:       0,
	})
	defer valkeyClient.Close()

	ctx := context.Background()

	_, err = valkeyClient.Ping(ctx).Result()
	if err != nil {
		log.Fatalf("Failed to connect to Valkey: %v", err)
	}
	log.Printf("Connected to Valkey at %s", valkeyAddr)

	// Configurar consumer
	msgs, err := channel.Consume(
		queueName,
		"",    // consumer
		true,  // auto-ack
		false, // exclusive
		false, // no-local
		false, // no-wait
		nil,   // args
	)
	if err != nil {
		log.Fatalf("Failed to register consumer: %v", err)
	}

	sigchan := make(chan os.Signal, 1)
	signal.Notify(sigchan, syscall.SIGINT, syscall.SIGTERM)

	log.Println("RabbitMQ consumer started, waiting for messages...")

	go func() {
		for msg := range msgs {
			log.Printf("Received message from RabbitMQ: %s", string(msg.Body))

			var data WeatherData
			if err := json.Unmarshal(msg.Body, &data); err != nil {
				log.Printf("Error unmarshaling message: %v", err)
				continue
			}

			if err := storeInValkey(ctx, valkeyClient, data); err != nil {
				log.Printf("Error storing in Valkey: %v", err)
				continue
			}

			log.Printf("Successfully stored in Valkey: %+v", data)
		}
	}()

	<-sigchan
	log.Println("Shutting down RabbitMQ consumer...")
}

func storeInValkey(ctx context.Context, client *redis.Client, data WeatherData) error {
	timestamp := time.Now().Unix()
	
	client.Incr(ctx, "total_reports")
	
	municipalityKey := "municipality:" + data.Municipality
	client.Incr(ctx, municipalityKey)
	
	weatherKey := "weather:" + data.Weather
	client.Incr(ctx, weatherKey)
	
	tempKey := "temperatures:" + data.Municipality
	client.RPush(ctx, tempKey, data.Temperature)
	
	humidityKey := "humidities:" + data.Municipality
	client.RPush(ctx, humidityKey, data.Humidity)
	
	recordKey := "record:" + data.Municipality + ":" + string(timestamp)
	jsonData, _ := json.Marshal(data)
	client.Set(ctx, recordKey, jsonData, 24*time.Hour)
	
	client.ZAdd(ctx, "records:"+data.Municipality, redis.Z{
		Score:  float64(timestamp),
		Member: jsonData,
	})

	return nil
}
