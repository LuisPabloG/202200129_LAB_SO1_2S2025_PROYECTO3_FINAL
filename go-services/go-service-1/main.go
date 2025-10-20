package main

import (
	"context"
	"encoding/json"
	pb "go-grpc-client/proto"
	"log"
	"net/http"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

// Estructura para recibir los datos JSON desde la API Rust
type WeatherTweet struct {
	Municipality string `json:"municipality"`
	Temperature  int32  `json:"temperature"`
	Humidity     int32  `json:"humidity"`
	Weather      string `json:"weather"`
}

// Mapeos para conversiones
var municipalityMap = map[string]pb.Municipalities{
	"mixco":     pb.Municipalities_mixco,
	"guatemala": pb.Municipalities_guatemala,
	"amatitlan": pb.Municipalities_amatitlan,
	"chinautla": pb.Municipalities_chinautla,
}

var weatherMap = map[string]pb.Weathers{
	"sunny":  pb.Weathers_sunny,
	"cloudy": pb.Weathers_cloudy,
	"rainy":  pb.Weathers_rainy,
	"foggy":  pb.Weathers_foggy,
}

func main() {
	// Iniciar servidor HTTP
	http.HandleFunc("/grpc-client", handleRequest)
	log.Println("Servidor Go (gRPC Client) iniciado en puerto 8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func handleRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Método no permitido", http.StatusMethodNotAllowed)
		return
	}

	// Parsear el JSON del cuerpo de la petición
	var tweet WeatherTweet
	if err := json.NewDecoder(r.Body).Decode(&tweet); err != nil {
		http.Error(w, "Error al parsear JSON: "+err.Error(), http.StatusBadRequest)
		return
	}

	log.Printf("Tweet recibido: %+v", tweet)

	// Enviar a ambos servicios gRPC (Kafka y RabbitMQ)
	kafkaStatus := sendToGrpcService("go-service-kafka-writer:50051", tweet)
	rabbitStatus := sendToGrpcService("go-service-rabbit-writer:50052", tweet)

	// Responder con el estado
	response := map[string]string{
		"kafka_status":  kafkaStatus,
		"rabbit_status": rabbitStatus,
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func sendToGrpcService(serviceAddr string, tweet WeatherTweet) string {
	// Conectar al servicio gRPC
	conn, err := grpc.Dial(serviceAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Printf("Error al conectar a %s: %v", serviceAddr, err)
		return "Error al conectar: " + err.Error()
	}
	defer conn.Close()

	// Crear cliente gRPC
	client := pb.NewWeatherTweetServiceClient(conn)

	// Convertir datos a formato gRPC
	municipality, ok := municipalityMap[tweet.Municipality]
	if !ok {
		municipality = pb.Municipalities_municipalities_unknown
	}

	weather, ok := weatherMap[tweet.Weather]
	if !ok {
		weather = pb.Weathers_weathers_unknown
	}

	// Crear request gRPC
	req := &pb.WeatherTweetRequest{
		Municipality: municipality,
		Temperature:  tweet.Temperature,
		Humidity:     tweet.Humidity,
		Weather:      weather,
	}

	// Llamar al RPC
	resp, err := client.SendTweet(context.Background(), req)
	if err != nil {
		log.Printf("Error al llamar SendTweet en %s: %v", serviceAddr, err)
		return "Error en RPC: " + err.Error()
	}

	log.Printf("Respuesta de %s: %s", serviceAddr, resp.Status)
	return resp.Status
}
