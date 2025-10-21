package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"os"

	"github.com/streadway/amqp"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	pb "rabbit-writer/proto"
)

type server struct {
	pb.UnimplementedWeatherTweetServiceServer
	channel    *amqp.Channel
	queueName  string
	routingKey string
}

func failOnError(err error, msg string) {
	if err != nil {
		log.Fatalf("%s: %s", msg, err)
	}
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

	// Crear el mensaje para RabbitMQ
	tweet := map[string]interface{}{
		"municipality": municipalityStr,
		"temperature":  req.Temperature,
		"humidity":     req.Humidity,
		"weather":      weatherStr,
	}

	// Convertir el mensaje a JSON
	body, err := json.Marshal(tweet)
	if err != nil {
		log.Printf("Error marshaling tweet: %v", err)
		return &pb.WeatherTweetResponse{Status: "error"}, err
	}

	// Publicar el mensaje en RabbitMQ
	err = s.channel.Publish(
		"",           // exchange
		s.routingKey, // routing key
		false,        // mandatory
		false,        // immediate
		amqp.Publishing{
			ContentType: "application/json",
			Body:        body,
		})

	if err != nil {
		log.Printf("Error publishing to RabbitMQ: %v", err)
		return &pb.WeatherTweetResponse{Status: "error"}, err
	}

	log.Println("Tweet sent to RabbitMQ successfully")
	return &pb.WeatherTweetResponse{Status: "ok"}, nil
}

func main() {
	// Configurar RabbitMQ
	rabbitURL := os.Getenv("RABBIT_URL")
	if rabbitURL == "" {
		rabbitURL = "amqp://guest:guest@rabbitmq:5672/"
	}

	queueName := os.Getenv("RABBIT_QUEUE")
	if queueName == "" {
		queueName = "weather-tweets"
	}

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

	// Configurar servidor gRPC
	port := os.Getenv("PORT")
	if port == "" {
		port = "50052"
	}

	lis, err := net.Listen("tcp", fmt.Sprintf(":%s", port))
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterWeatherTweetServiceServer(s, &server{
		channel:    ch,
		queueName:  queueName,
		routingKey: q.Name,
	})
	reflection.Register(s)

	log.Printf("RabbitMQ Writer gRPC server listening on port %s", port)
	if err := s.Serve(lis); err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
}
