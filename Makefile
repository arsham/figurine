# Makefile for Figurine

# Variables
BINARY_NAME=figurine
DOCKER_IMAGE=figurine
DOCKER_CONTAINER=figurine-container

# Go commands
build:
	go build -o $(BINARY_NAME) .

install:
	go install .

test:
	go test -v ./...

clean:
	go clean
	rm -f $(BINARY_NAME)

# Docker commands
docker-build:
	docker build -t $(DOCKER_IMAGE) .

docker-run:
	docker run --rm --name $(DOCKER_CONTAINER) $(DOCKER_IMAGE)

docker-clean:
	docker rm -f $(DOCKER_CONTAINER) 2>/dev/null || true
	docker rmi -f $(DOCKER_IMAGE) 2>/dev/null || true

.PHONY: build install test clean docker-build docker-run docker-clean
