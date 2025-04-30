# Build stage
FROM golang:1.18-alpine AS build

WORKDIR /app

COPY . .

RUN go build -o figurine .

# Final stage
FROM alpine:latest

WORKDIR /app

COPY --from=build /app/figurine .

ENTRYPOINT ["./figurine"]
