# Build stage
FROM golang:1.20-alpine AS build

WORKDIR /app

# Install dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary with proper flags
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -ldflags="-s -w -X main.version=${VERSION}" -o figurine .

# Final stage - minimal image
FROM alpine:latest

# Add CA certificates for any HTTPS requests
RUN apk --no-cache add ca-certificates

# Create non-root user for security
RUN adduser -D -u 10001 appuser
WORKDIR /home/appuser

# Copy only the binary from the build stage
COPY --from=build /app/figurine .
RUN chmod +x ./figurine

# Use non-root user
USER appuser

ENTRYPOINT ["./figurine"]
