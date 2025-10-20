package main

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/segmentio/kafka-go"
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

func main() {
	kafkaBroker := getEnv("KAFKA_BROKER", "kafka-service:9092")
	kafkaTopic := getEnv("KAFKA_TOPIC", "weather-tweets")
	kafkaGroupID := getEnv("KAFKA_GROUP_ID", "kafka-consumer-group")
	valkeyAddr := getEnv("VALKEY_ADDR", "valkey-service:6379")

	// Configurar Kafka Reader
	reader := kafka.NewReader(kafka.ReaderConfig{
		Brokers:  []string{kafkaBroker},
		Topic:    kafkaTopic,
		GroupID:  kafkaGroupID,
		MinBytes: 10e3, // 10KB
		MaxBytes: 10e6, // 10MB
	})
	defer reader.Close()

	log.Printf("Connected to Kafka broker: %s, topic: %s", kafkaBroker, kafkaTopic)

	// Configurar Valkey (Redis) Client
	valkeyClient := redis.NewClient(&redis.Options{
		Addr:     valkeyAddr,
		Password: "",
		DB:       0,
	})
	defer valkeyClient.Close()

	ctx := context.Background()

	// Verificar conexión a Valkey
	_, err := valkeyClient.Ping(ctx).Result()
	if err != nil {
		log.Fatalf("Failed to connect to Valkey: %v", err)
	}
	log.Printf("Connected to Valkey at %s", valkeyAddr)

	// Manejar señales de terminación
	sigchan := make(chan os.Signal, 1)
	signal.Notify(sigchan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigchan
		log.Println("Shutting down Kafka consumer...")
		reader.Close()
		valkeyClient.Close()
		os.Exit(0)
	}()

	log.Println("Kafka consumer started, waiting for messages...")

	// Consumir mensajes
	for {
		msg, err := reader.ReadMessage(ctx)
		if err != nil {
			log.Printf("Error reading message: %v", err)
			continue
		}

		log.Printf("Received message from Kafka: %s", string(msg.Value))

		var data WeatherData
		if err := json.Unmarshal(msg.Value, &data); err != nil {
			log.Printf("Error unmarshaling message: %v", err)
			continue
		}

		// Almacenar en Valkey
		if err := storeInValkey(ctx, valkeyClient, data); err != nil {
			log.Printf("Error storing in Valkey: %v", err)
			continue
		}

		log.Printf("Successfully stored in Valkey: %+v", data)
	}
}

func storeInValkey(ctx context.Context, client *redis.Client, data WeatherData) error {
	timestamp := time.Now().Unix()
	
	// Incrementar contador total de reportes
	client.Incr(ctx, "total_reports")

	// Incrementar contador por municipio
	municipalityKey := "municipality:" + data.Municipality
	client.Incr(ctx, municipalityKey)

	// Incrementar contador por condición climática
	weatherKey := "weather:" + data.Weather
	client.Incr(ctx, weatherKey)

	// Agregar temperatura a lista para calcular promedio
	tempKey := "temperatures:" + data.Municipality
	client.RPush(ctx, tempKey, data.Temperature)

	// Agregar humedad a lista para calcular promedio
	humidityKey := "humidities:" + data.Municipality
	client.RPush(ctx, humidityKey, data.Humidity)

	// Almacenar registro completo con timestamp
	recordKey := "record:" + data.Municipality + ":" + string(timestamp)
	jsonData, _ := json.Marshal(data)
	client.Set(ctx, recordKey, jsonData, 24*time.Hour) // TTL de 24 horas

	// Almacenar en lista ordenada por timestamp
	client.ZAdd(ctx, "records:"+data.Municipality, redis.Z{
		Score:  float64(timestamp),
		Member: jsonData,
	})

	return nil
}
