# Build stage
FROM golang:1.18-alpine AS build

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o figurine .

# Final stage
FROM alpine:latest

WORKDIR /app

COPY --from=build /app/figurine .

ENTRYPOINT ["./figurine"]
