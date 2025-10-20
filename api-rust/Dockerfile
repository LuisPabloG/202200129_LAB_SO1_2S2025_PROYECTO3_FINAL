# --- Stage 1: Build ---
FROM rust:1.70 as builder
WORKDIR /usr/src/app
RUN apt-get update && apt-get install -y pkg-config libssl-dev
COPY . .
# Build
RUN cargo install --path .

# --- Stage 2: Final Image ---
FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y ca-certificates libssl-dev && rm -rf /var/lib/apt/lists/*
# Copiar el binario compilado
COPY --from=builder /usr/local/cargo/bin/api-rust /usr/local/bin/api-rust

# Exponer puerto
EXPOSE 8000

# Comando de ejecución
CMD ["api-rust"]