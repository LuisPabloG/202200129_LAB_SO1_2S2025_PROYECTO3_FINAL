FROM rust:1.70 as builder

WORKDIR /usr/src/rust-api
COPY . .

RUN cargo build --release

FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y libssl-dev ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/rust-api/target/release/rust-api /usr/local/bin/rust-api

ENV HOST=0.0.0.0
ENV PORT=8000
ENV GO_API_URL=http://go-api-service:8080/tweet

EXPOSE 8000

CMD ["rust-api"]