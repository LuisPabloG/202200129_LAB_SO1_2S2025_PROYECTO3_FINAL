#!/bin/bash
# Este script genera los archivos Go desde el proto

mkdir -p proto

protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       ./proto/weathertweet.proto