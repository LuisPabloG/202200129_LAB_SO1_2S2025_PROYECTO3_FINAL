package main

import (
	"context"
	"encoding/json"
	"log"
	"net"
	"os"

	"github.com/confluentinc/confluent-kafka-go/v2/kafka"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	pb "kafka-writer/proto"
)

type server struct {
	pb.UnimplementedWeatherTweetServiceServer
	producer *kafka.Producer
	topic    string
}

func (s *server) SendTweet(ctx context.Context, req *pb.WeatherTweetRequest) (*pb.WeatherTweetResponse, error) {
	log.Printf("Received tweet: %v", req)

	// Convertir el enum de municipio a string
	municipalityStr := req.Municipality.String()
	if req.Municipality == pb.Municipalities_municipalities_unknown {
		municipalityStr = "unknown"
	}

	// Convertir el enum de clima a string
	weatherStr := req.Weather.String()
	if req.Weather == pb.Weathers_weathers_unknown {
		weatherStr = "unknown"
	}

	// Crear el mensaje para Kafka
	tweet := map[string]interface{}{
		"municipality": municipalityStr,
		"temperature":  req.Temperature,
		"humidity":     req.Humidity,
		"weather":      weatherStr,
	}

	// Convertir el mensaje a JSON
	value, err := json.Marshal(tweet)
	if err != nil {
		log.Printf("Error marshaling tweet: %v", err)
		return &pb.WeatherTweetResponse{Status: "error"}, err
	}

	// Publicar el mensaje en Kafka
	err = s.producer.Produce(&kafka.Message{
		TopicPartition: kafka.TopicPartition{Topic: &s.topic, Partition: kafka.PartitionAny},
		Value:          value,
	}, nil)

	if err != nil {
		log.Printf("Error publishing to Kafka: %v", err)
		return &pb.WeatherTweetResponse{Status: "error"}, err
	}

	// Esperar eventos pendientes para asegurar que se ha enviado el mensaje
	s.producer.Flush(15 * 1000)
	log.Println("Tweet sent to Kafka successfully")

	return &pb.WeatherTweetResponse{Status: "ok"}, nil
}

func main() {
	// Configurar Kafka
	brokers := os.Getenv("KAFKA_BROKERS")
	if brokers == "" {
		brokers = "kafka:9092"
	}

	topic := os.Getenv("KAFKA_TOPIC")
	if topic == "" {
		topic = "weather-tweets"
	}

	producer, err := kafka.NewProducer(&kafka.ConfigMap{
		"bootstrap.servers": brokers,
		"acks":              "all",
	})
	if err != nil {
		log.Fatalf("Failed to create Kafka producer: %v", err)
	}
	defer producer.Close()

	// Manejar eventos de entrega de Kafka
	go func() {
		for e := range producer.Events() {
			switch ev := e.(type) {
			case *kafka.Message:
				if ev.TopicPartition.Error != nil {
					log.Printf("Delivery failed: %v", ev.TopicPartition.Error)
				} else {
					log.Printf("Delivered message to %v", ev.TopicPartition)
				}
			}
		}
	}()

	// Configurar servidor gRPC
	port := os.Getenv("PORT")
	if port == "" {
		port = "50051"
	}

	lis, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterWeatherTweetServiceServer(s, &server{
		producer: producer,
		topic:    topic,
	})
	reflection.Register(s)

	log.Printf("Kafka Writer gRPC server listening on port %s", port)
	if err := s.Serve(lis); err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
}
