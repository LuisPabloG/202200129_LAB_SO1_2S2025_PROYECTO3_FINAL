package main

import (
	"context"
	"encoding/json"
	"log"
	"net"
	"os"

	"github.com/segmentio/kafka-go"
	"google.golang.org/grpc"
	pb "go-kafka-writer/proto"
)

type server struct {
	pb.UnimplementedWeatherTweetServiceServer
	kafkaWriter *kafka.Writer
}

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

func (s *server) SendTweet(ctx context.Context, req *pb.WeatherTweetRequest) (*pb.WeatherTweetResponse, error) {
	log.Printf("Kafka Writer received: Municipality=%s, Temp=%d, Humidity=%d, Weather=%s",
		req.Municipality.String(), req.Temperature, req.Humidity, req.Weather.String())

	// Convertir a JSON
	data := map[string]interface{}{
		"municipality": req.Municipality.String(),
		"temperature":  req.Temperature,
		"humidity":     req.Humidity,
		"weather":      req.Weather.String(),
	}

	jsonData, err := json.Marshal(data)
	if err != nil {
		log.Printf("Error marshaling data: %v", err)
		return &pb.WeatherTweetResponse{Status: "error"}, err
	}

	// Enviar a Kafka
	err = s.kafkaWriter.WriteMessages(ctx, kafka.Message{
		Key:   []byte(req.Municipality.String()),
		Value: jsonData,
	})

	if err != nil {
		log.Printf("Error writing to Kafka: %v", err)
		return &pb.WeatherTweetResponse{Status: "error"}, err
	}

	log.Printf("Successfully wrote to Kafka")
	return &pb.WeatherTweetResponse{Status: "success"}, nil
}

func main() {
	kafkaBroker := getEnv("KAFKA_BROKER", "kafka-service:9092")
	kafkaTopic := getEnv("KAFKA_TOPIC", "weather-tweets")
	port := getEnv("GRPC_PORT", "50051")

	// Configurar Kafka Writer
	kafkaWriter := &kafka.Writer{
		Addr:     kafka.TCP(kafkaBroker),
		Topic:    kafkaTopic,
		Balancer: &kafka.LeastBytes{},
	}
	defer kafkaWriter.Close()

	log.Printf("Connected to Kafka broker: %s, topic: %s", kafkaBroker, kafkaTopic)

	// Configurar gRPC Server
	lis, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	grpcServer := grpc.NewServer()
	pb.RegisterWeatherTweetServiceServer(grpcServer, &server{kafkaWriter: kafkaWriter})

	log.Printf("Kafka Writer gRPC server listening on port %s", port)
	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
}
