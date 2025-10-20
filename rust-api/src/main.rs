use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use serde::{Deserialize, Serialize};
use std::env;

#[derive(Debug, Serialize, Deserialize, Clone)]
struct WeatherTweet {
    municipality: String,
    temperature: i32,
    humidity: i32,
    weather: String,
}

#[derive(Serialize)]
struct ApiResponse {
    status: String,
    message: String,
}

async fn health_check() -> impl Responder {
    HttpResponse::Ok().json(ApiResponse {
        status: "ok".to_string(),
        message: "Rust API is running".to_string(),
    })
}

async fn receive_tweet(tweet: web::Json<WeatherTweet>) -> impl Responder {
    let go_service_url = env::var("GO_SERVICE_URL")
        .unwrap_or_else(|_| "http://go-grpc-client-service:8080".to_string());
    
    log::info!("Received tweet: {:?}", tweet);
    
    // Enviar al servicio Go
    let client = reqwest::Client::new();
    match client
        .post(format!("{}/api/tweet", go_service_url))
        .json(&tweet.into_inner())
        .send()
        .await
    {
        Ok(response) => {
            if response.status().is_success() {
                log::info!("Successfully forwarded to Go service");
                HttpResponse::Ok().json(ApiResponse {
                    status: "success".to_string(),
                    message: "Tweet processed".to_string(),
                })
            } else {
                log::error!("Go service returned error: {}", response.status());
                HttpResponse::InternalServerError().json(ApiResponse {
                    status: "error".to_string(),
                    message: "Failed to process tweet".to_string(),
                })
            }
        }
        Err(e) => {
            log::error!("Failed to forward to Go service: {}", e);
            HttpResponse::InternalServerError().json(ApiResponse {
                status: "error".to_string(),
                message: format!("Service error: {}", e),
            })
        }
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));
    
    let port = env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    let bind_address = format!("0.0.0.0:{}", port);
    
    log::info!("Starting Rust API on {}", bind_address);
    
    HttpServer::new(|| {
        App::new()
            .route("/health", web::get().to(health_check))
            .route("/api/tweet", web::post().to(receive_tweet))
    })
    .bind(&bind_address)?
    .run()
    .await
}
