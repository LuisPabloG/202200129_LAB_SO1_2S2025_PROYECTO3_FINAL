package main

import (
	"context"
	"fmt"
	"log"
	"net"

	pb "kafka-writer/proto"

	"github.com/segmentio/kafka-go"
	"google.golang.org/grpc"
)

const (
	port       = ":50051"
	kafkaTopic = "weather-tweets"
	kafkaAddr  = "kafka:9092"
)

// Servidor gRPC
type server struct {
	pb.UnimplementedWeatherTweetServiceServer
}

// Implementación del método SendTweet
func (s *server) SendTweet(ctx context.Context, req *pb.WeatherTweetRequest) (*pb.WeatherTweetResponse, error) {
	log.Printf("Tweet recibido en Kafka Writer: %v", req)

	// Crear un escritor de Kafka
	writer := kafka.NewWriter(kafka.WriterConfig{
		Brokers: []string{kafkaAddr},
		Topic:   kafkaTopic,
	})
	defer writer.Close()

	// Preparar el mensaje
	municipality := pb.Municipalities_name[int32(req.Municipality)]
	weather := pb.Weathers_name[int32(req.Weather)]

	// Crear un mensaje JSON simple para Kafka
	message := fmt.Sprintf(`{
		"municipality": "%s",
		"temperature": %d,
		"humidity": %d,
		"weather": "%s"
	}`, municipality, req.Temperature, req.Humidity, weather)

	// Escribir el mensaje en Kafka
	err := writer.WriteMessages(ctx, kafka.Message{
		Value: []byte(message),
	})

	if err != nil {
		log.Printf("Error al escribir en Kafka: %v", err)
		return &pb.WeatherTweetResponse{Status: "Error: " + err.Error()}, nil
	}

	log.Println("Mensaje enviado a Kafka correctamente")
	return &pb.WeatherTweetResponse{Status: "Mensaje enviado a Kafka correctamente"}, nil
}

func main() {
	// Iniciar servidor gRPC
	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatalf("Error al escuchar: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterWeatherTweetServiceServer(s, &server{})

	log.Printf("Servidor Kafka Writer escuchando en %s", port)
	if err := s.Serve(lis); err != nil {
		log.Fatalf("Error al servir: %v", err)
	}
}
