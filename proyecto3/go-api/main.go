package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pb "go-api/proto"
)

// WeatherTweet representa la estructura de un tweet sobre el clima
type WeatherTweet struct {
	Municipality string `json:"municipality"`
	Temperature  int32  `json:"temperature"`
	Humidity     int32  `json:"humidity"`
	Weather      string `json:"weather"`
}

// convertToProtoMunicipality convierte un string a un enum de Municipalities
func convertToProtoMunicipality(municipality string) pb.Municipalities {
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

// convertToProtoWeather convierte un string a un enum de Weathers
func convertToProtoWeather(weather string) pb.Weathers {
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

func main() {
	r := gin.Default()

	kafkaWriterAddr := os.Getenv("KAFKA_WRITER_ADDR")
	if kafkaWriterAddr == "" {
		kafkaWriterAddr = "kafka-writer-service:50051"
	}

	rabbitWriterAddr := os.Getenv("RABBIT_WRITER_ADDR")
	if rabbitWriterAddr == "" {
		rabbitWriterAddr = "rabbit-writer-service:50052"
	}

	// Endpoint para chequeo de salud
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "Go API is running"})
	})

	// Endpoint para recibir tweets
	r.POST("/tweet", func(c *gin.Context) {
		var tweet WeatherTweet
		if err := c.BindJSON(&tweet); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Invalid request format"})
			return
		}

		log.Printf("Received tweet: %+v", tweet)

		// Validar los valores del tweet
		if tweet.Municipality == "" || tweet.Weather == "" {
			c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Municipality and weather are required"})
			return
		}

		// Enviar a ambos writers de forma concurrente
		var wg sync.WaitGroup
		wg.Add(2)

		// Canal para errores
		errChan := make(chan error, 2)

		// Enviar a Kafka Writer
		go func() {
			defer wg.Done()
			err := sendToWriter(kafkaWriterAddr, &tweet)
			if err != nil {
				log.Printf("Error sending to Kafka Writer: %v", err)
				errChan <- err
			}
		}()

		// Enviar a RabbitMQ Writer
		go func() {
			defer wg.Done()
			err := sendToWriter(rabbitWriterAddr, &tweet)
			if err != nil {
				log.Printf("Error sending to RabbitMQ Writer: %v", err)
				errChan <- err
			}
		}()

		// Esperar a que ambas goroutines terminen
		wg.Wait()
		close(errChan)

		// Verificar si hubo errores
		errors := []error{}
		for err := range errChan {
			errors = append(errors, err)
		}

		if len(errors) > 0 {
			c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Error sending tweet to writers"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Go API starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func sendToWriter(addr string, tweet *WeatherTweet) error {
	// Configurar conexión gRPC
	conn, err := grpc.Dial(addr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return err
	}
	defer conn.Close()

	// Crear cliente gRPC
	client := pb.NewWeatherTweetServiceClient(conn)

	// Preparar contexto con timeout
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*5)
	defer cancel()

	// Convertir tweet a formato proto
	protoTweet := &pb.WeatherTweetRequest{
		Municipality: convertToProtoMunicipality(tweet.Municipality),
		Temperature:  tweet.Temperature,
		Humidity:     tweet.Humidity,
		Weather:      convertToProtoWeather(tweet.Weather),
	}

	// Enviar tweet al writer
	_, err = client.SendTweet(ctx, protoTweet)
	return err
}
