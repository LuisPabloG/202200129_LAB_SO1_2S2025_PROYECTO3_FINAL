package main

import (
	"context"
	"fmt"
	"log"
	"net"

	pb "rabbit-writer/proto"

	"github.com/streadway/amqp"
	"google.golang.org/grpc"
)

const (
	port             = ":50052"
	rabbitMQURL      = "amqp://guest:guest@rabbitmq:5672/"
	rabbitMQExchange = "weather_exchange"
	rabbitMQQueue    = "weather_queue"
)

// Servidor gRPC
type server struct {
	pb.UnimplementedWeatherTweetServiceServer
}

// Implementación del método SendTweet
func (s *server) SendTweet(ctx context.Context, req *pb.WeatherTweetRequest) (*pb.WeatherTweetResponse, error) {
	log.Printf("Tweet recibido en RabbitMQ Writer: %v", req)

	// Conectar a RabbitMQ
	conn, err := amqp.Dial(rabbitMQURL)
	if err != nil {
		log.Printf("Error al conectar con RabbitMQ: %v", err)
		return &pb.WeatherTweetResponse{Status: "Error de conexión RabbitMQ: " + err.Error()}, nil
	}
	defer conn.Close()

	ch, err := conn.Channel()
	if err != nil {
		log.Printf("Error al abrir canal: %v", err)
		return &pb.WeatherTweetResponse{Status: "Error de canal: " + err.Error()}, nil
	}
	defer ch.Close()

	// Declarar exchange
	err = ch.ExchangeDeclare(
		rabbitMQExchange, // nombre
		"fanout",         // tipo
		true,             // durable
		false,            // auto-eliminado
		false,            // interno
		false,            // no-espera
		nil,              // argumentos
	)
	if err != nil {
		log.Printf("Error al declarar exchange: %v", err)
		return &pb.WeatherTweetResponse{Status: "Error de exchange: " + err.Error()}, nil
	}

	// Declarar cola
	q, err := ch.QueueDeclare(
		rabbitMQQueue, // nombre
		false,         // durable
		false,         // eliminar cuando no está en uso
		false,         // exclusiva
		false,         // no-espera
		nil,           // argumentos
	)
	if err != nil {
		log.Printf("Error al declarar cola: %v", err)
		return &pb.WeatherTweetResponse{Status: "Error de cola: " + err.Error()}, nil
	}

	// Vincular cola al exchange
	err = ch.QueueBind(
		q.Name,           // nombre de la cola
		"",               // clave de enrutamiento
		rabbitMQExchange, // exchange
		false,            // no-espera
		nil,              // argumentos
	)
	if err != nil {
		log.Printf("Error al vincular cola: %v", err)
		return &pb.WeatherTweetResponse{Status: "Error de vinculación: " + err.Error()}, nil
	}

	// Preparar el mensaje
	municipality := pb.Municipalities_name[int32(req.Municipality)]
	weather := pb.Weathers_name[int32(req.Weather)]

	// Crear un mensaje JSON simple
	message := fmt.Sprintf(`{
		"municipality": "%s",
		"temperature": %d,
		"humidity": %d,
		"weather": "%s"
	}`, municipality, req.Temperature, req.Humidity, weather)

	// Publicar mensaje
	err = ch.Publish(
		rabbitMQExchange, // exchange
		"",               // clave de enrutamiento
		false,            // obligatorio
		false,            // inmediato
		amqp.Publishing{
			ContentType: "application/json",
			Body:        []byte(message),
		})
	if err != nil {
		log.Printf("Error al publicar mensaje: %v", err)
		return &pb.WeatherTweetResponse{Status: "Error de publicación: " + err.Error()}, nil
	}

	log.Println("Mensaje enviado a RabbitMQ correctamente")
	return &pb.WeatherTweetResponse{Status: "Mensaje enviado a RabbitMQ correctamente"}, nil
}

func main() {
	// Iniciar servidor gRPC
	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatalf("Error al escuchar: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterWeatherTweetServiceServer(s, &server{})

	log.Printf("Servidor RabbitMQ Writer escuchando en %s", port)
	if err := s.Serve(lis); err != nil {
		log.Fatalf("Error al servir: %v", err)
	}
}
