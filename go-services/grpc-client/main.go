package main

import (
	"log"
	"os"
	"time"
)

func main() {
	log.Println("gRPC Client Service started")

	grpcServerAddr := os.Getenv("GRPC_SERVER_ADDR")
	if grpcServerAddr == "" {
		grpcServerAddr = "grpc-server:50051"
	}

	log.Printf("Will connect to gRPC server at: %s", grpcServerAddr)

	// Simulate work
	ticker := time.NewTicker(5 * time.Second)
	for range ticker.C {
		log.Println("gRPC Client: Processing tweets...")
	}
}
