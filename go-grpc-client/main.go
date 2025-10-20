package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	pb "go-grpc-client/proto"
)

type WeatherTweet struct {
	Municipality string `json:"municipality"`
	Temperature  int32  `json:"temperature"`
	Humidity     int32  `json:"humidity"`
	Weather      string `json:"weather"`
}

var (
	kafkaClient    pb.WeatherTweetServiceClient
	rabbitmqClient pb.WeatherTweetServiceClient
)

func init() {
	// Conectar a Kafka Writer
	kafkaAddr := getEnv("KAFKA_WRITER_ADDR", "go-kafka-writer-service:50051")
	kafkaConn, err := grpc.Dial(kafkaAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Printf("Failed to connect to Kafka writer: %v", err)
	} else {
		kafkaClient = pb.NewWeatherTweetServiceClient(kafkaConn)
		log.Printf("Connected to Kafka writer at %s", kafkaAddr)
	}

	// Conectar a RabbitMQ Writer
	rabbitmqAddr := getEnv("RABBITMQ_WRITER_ADDR", "go-rabbitmq-writer-service:50052")
	rabbitmqConn, err := grpc.Dial(rabbitmqAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Printf("Failed to connect to RabbitMQ writer: %v", err)
	} else {
		rabbitmqClient = pb.NewWeatherTweetServiceClient(rabbitmqConn)
		log.Printf("Connected to RabbitMQ writer at %s", rabbitmqAddr)
	}
}

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

func municipalityToEnum(municipality string) pb.Municipalities {
	switch municipality {
	case "mixco":
		return pb.Municipalities_mixco
	case "guatemala":
		return pb.Municipalities_guatemala
	case "amatitlan":
		return pb.Municipalities_amatitlan
	case "chinautla":
		return pb.Municipalities_chinautla
	default:
		return pb.Municipalities_municipalities_unknown
	}
}

func weatherToEnum(weather string) pb.Weathers {
	switch weather {
	case "sunny":
		return pb.Weathers_sunny
	case "cloudy":
		return pb.Weathers_cloudy
	case "rainy":
		return pb.Weathers_rainy
	case "foggy":
		return pb.Weathers_foggy
	default:
		return pb.Weathers_weathers_unknown
	}
}

func handleTweet(c *gin.Context) {
	var tweet WeatherTweet
	if err := c.ShouldBindJSON(&tweet); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	log.Printf("Received tweet: %+v", tweet)

	// Crear request gRPC
	request := &pb.WeatherTweetRequest{
		Municipality: municipalityToEnum(tweet.Municipality),
		Temperature:  tweet.Temperature,
		Humidity:     tweet.Humidity,
		Weather:      weatherToEnum(tweet.Weather),
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Enviar a Kafka
	go func() {
		if kafkaClient != nil {
			_, err := kafkaClient.SendTweet(ctx, request)
			if err != nil {
				log.Printf("Error sending to Kafka: %v", err)
			} else {
				log.Printf("Tweet sent to Kafka successfully")
			}
		}
	}()

	// Enviar a RabbitMQ
	go func() {
		if rabbitmqClient != nil {
			_, err := rabbitmqClient.SendTweet(ctx, request)
			if err != nil {
				log.Printf("Error sending to RabbitMQ: %v", err)
			} else {
				log.Printf("Tweet sent to RabbitMQ successfully")
			}
		}
	}()

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Tweet processed",
	})
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status": "ok",
		"service": "go-grpc-client",
	})
}

func main() {
	port := getEnv("PORT", "8080")
	
	router := gin.Default()
	router.POST("/api/tweet", handleTweet)
	router.GET("/health", healthCheck)

	log.Printf("Starting Go gRPC Client on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
