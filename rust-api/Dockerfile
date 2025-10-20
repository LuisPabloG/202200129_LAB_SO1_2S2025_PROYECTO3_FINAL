FROM rust:1.75 AS builder
WORKDIR /usr/src/app
COPY Cargo.toml ./
COPY src ./src
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/src/app/target/release/rust-api /usr/local/bin/rust-api
ENV PORT=3000
EXPOSE 3000
CMD ["rust-api"]
