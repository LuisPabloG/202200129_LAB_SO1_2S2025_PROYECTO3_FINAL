package main

import (
	"context"
	"encoding/json"
	"log"
	"net"
	"os"
	"time"

	"github.com/streadway/amqp"
	"google.golang.org/grpc"
	pb "go-rabbitmq-writer/proto"
)

type server struct {
	pb.UnimplementedWeatherTweetServiceServer
	channel *amqp.Channel
	queue   string
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

func (s *server) SendTweet(ctx context.Context, req *pb.WeatherTweetRequest) (*pb.WeatherTweetResponse, error) {
	log.Printf("RabbitMQ Writer received: Municipality=%s, Temp=%d, Humidity=%d, Weather=%s",
		req.Municipality.String(), req.Temperature, req.Humidity, req.Weather.String())

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

	err = s.channel.Publish(
		"",      // exchange
		s.queue, // routing key
		false,   // mandatory
		false,   // immediate
		amqp.Publishing{
			ContentType: "application/json",
			Body:        jsonData,
		})

	if err != nil {
		log.Printf("Error publishing to RabbitMQ: %v", err)
		return &pb.WeatherTweetResponse{Status: "error"}, err
	}

	log.Printf("Successfully published to RabbitMQ")
	return &pb.WeatherTweetResponse{Status: "success"}, nil
}

func main() {
	rabbitmqURL := getEnv("RABBITMQ_URL", "amqp://guest:guest@rabbitmq-service:5672/")
	queueName := getEnv("RABBITMQ_QUEUE", "weather-tweets")
	port := getEnv("GRPC_PORT", "50052")

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

	lis, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	grpcServer := grpc.NewServer()
	pb.RegisterWeatherTweetServiceServer(grpcServer, &server{
		channel: channel,
		queue:   queueName,
	})

	log.Printf("RabbitMQ Writer gRPC server listening on port %s", port)
	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
}
