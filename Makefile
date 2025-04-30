# Makefile for Figurine

# Variables
BINARY_NAME=figurine
VERSION=$(shell git describe --tags --always --dirty)
LDFLAGS=-ldflags "-s -w -X main.version=$(VERSION)"
GO_FILES=$(shell find . -name "*.go" -type f)
DOCKER_IMAGE=figurine
DOCKER_CONTAINER=figurine-container
PLATFORMS=linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64
OUTPUT_DIR=dist

# Go commands
build:
	go build $(LDFLAGS) -o $(BINARY_NAME) .

install:
	go install $(LDFLAGS) .

test:
	go test -v ./...

clean:
	go clean
	[ -f $(BINARY_NAME) ] && rm -f $(BINARY_NAME) || true
	rm -rf $(OUTPUT_DIR)

# Multi-platform builds
build-all: clean
	mkdir -p $(OUTPUT_DIR)
	$(foreach platform,$(PLATFORMS),\
		$(eval OS := $(word 1,$(subst /, ,$(platform)))) \
		$(eval ARCH := $(word 2,$(subst /, ,$(platform)))) \
		$(eval EXTENSION := $(if $(filter windows,$(OS)),.exe,)) \
		echo "Building $(OS)/$(ARCH)..." && \
		GOOS=$(OS) GOARCH=$(ARCH) CGO_ENABLED=0 \
			go build $(LDFLAGS) -o $(OUTPUT_DIR)/$(BINARY_NAME)_$(OS)_$(ARCH)$(EXTENSION) . && \
		cd $(OUTPUT_DIR) && \
		tar -czvf $(BINARY_NAME)_$(OS)_$(ARCH).tar.gz $(BINARY_NAME)_$(OS)_$(ARCH)$(EXTENSION) && \
		cd - ;\
	)

release: build-all
	cd $(OUTPUT_DIR) && sha256sum *.tar.gz > checksums.txt

# Docker commands
docker-build:
	docker build -t $(DOCKER_IMAGE) .

docker-run:
	docker run --rm --name $(DOCKER_CONTAINER) $(DOCKER_IMAGE)

docker-clean:
	docker rm -f $(DOCKER_CONTAINER) 2>/dev/null || true
	docker rmi -f $(DOCKER_IMAGE) 2>/dev/null || true

# Docker multi-platform build
docker-buildx:
	docker buildx create --use --name multiplatform-builder || true
	docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 \
		--tag $(DOCKER_IMAGE):$(VERSION) \
		--tag $(DOCKER_IMAGE):latest \
		--push .

.PHONY: build install test clean build-all release docker-build docker-run docker-clean docker-buildx
