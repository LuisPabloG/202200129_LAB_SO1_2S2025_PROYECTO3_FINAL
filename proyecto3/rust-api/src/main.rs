use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use serde::{Deserialize, Serialize};
use std::env;
use log::{info, error};

#[derive(Debug, Serialize, Deserialize)]
enum Municipalities {
    #[serde(rename = "municipalities_unknown")]
    Unknown,
    #[serde(rename = "mixco")]
    Mixco,
    #[serde(rename = "guatemala")]
    Guatemala,
    #[serde(rename = "amatitlan")]
    Amatitlan,
    #[serde(rename = "chinautla")]
    Chinautla,
}

#[derive(Debug, Serialize, Deserialize)]
enum Weathers {
    #[serde(rename = "weathers_unknown")]
    Unknown,
    #[serde(rename = "sunny")]
    Sunny,
    #[serde(rename = "cloudy")]
    Cloudy,
    #[serde(rename = "rainy")]
    Rainy,
    #[serde(rename = "foggy")]
    Foggy,
}

#[derive(Debug, Serialize, Deserialize)]
struct WeatherTweet {
    municipality: String,
    temperature: i32,
    humidity: i32,
    weather: String,
}

async fn health() -> impl Responder {
    HttpResponse::Ok().body("Rust API is running")
}

async fn receive_tweet(tweet: web::Json<WeatherTweet>) -> impl Responder {
    info!("Received tweet: {:?}", tweet);
    
    let go_api_url = env::var("GO_API_URL").unwrap_or_else(|_| "http://go-api-service:8080/tweet".to_string());
    
    // Enviar el tweet al servicio Go
    match reqwest::Client::new()
        .post(&go_api_url)
        .json(&tweet.0)
        .send()
        .await
    {
        Ok(_) => {
            info!("Tweet sent to Go API successfully");
            HttpResponse::Ok().json(serde_json::json!({"status": "ok"}))
        },
        Err(e) => {
            error!("Error sending tweet to Go API: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({"status": "error", "message": e.to_string()}))
        }
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));
    
    let host = env::var("HOST").unwrap_or_else(|_| "0.0.0.0".to_string());
    let port = env::var("PORT").unwrap_or_else(|_| "8000".to_string());
    let bind_address = format!("{}:{}", host, port);
    
    info!("Rust API starting on {}", bind_address);
    
    HttpServer::new(|| {
        App::new()
            .route("/health", web::get().to(health))
            .route("/tweet", web::post().to(receive_tweet))
    })
    .bind(bind_address)?
    .run()
    .await
}