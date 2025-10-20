use actix_web::{web, App, HttpResponse, HttpServer, Responder, post};
use serde::{Deserialize, Serialize};
use std::env;

// Estructura JSON que esperamos de Locust
#[derive(Deserialize, Serialize, Debug)]
struct WeatherTweet {
    municipality: String,
    temperature: i32,
    humidity: i32,
    weather: String,
}

// URL del Deployment 1 de Go (usamos el nombre del servicio de K8s)
// Este servicio (go-service-1) lo crearemos más adelante.
const GO_SERVICE_URL: &str = "http://go-service-1:8080/grpc-client";

#[post("/tweet")]
async fn receive_tweet(tweet: web::Json<WeatherTweet>) -> impl Responder {
    log::info!("Tweet recibido: {:?}", tweet);

    // Reenviar al Deployment 1 de Go
    let client = reqwest::Client::new();
    match client.post(GO_SERVICE_URL)
                .json(&tweet.into_inner())
                .send()
                .await {
        Ok(response) => {
            let status = response.status();
            let text = response.text().await.unwrap_or_default();
            log::info!("Respuesta de Go Service: {} - {}", status, text);
            HttpResponse::Ok().body(format!("Go Service respondió: {}", text))
        },
        Err(e) => {
            log::error!("Error llamando a Go Service: {}", e);
            HttpResponse::InternalServerError().body(format!("Error llamando a servicio Go: {}", e))
        }
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Inicializar logger
    env::set_var("RUST_LOG", "info");
    env_logger::init();

    log::info!("--- Servidor Rust API escuchando en 0.0.0.0:8000 ---");
    HttpServer::new(|| {
        App::new().service(receive_tweet)
    })
    .bind(("0.0.0.0", 8000))?
    .run()
    .await
}