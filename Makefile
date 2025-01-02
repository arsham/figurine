help: ## Show help messages.
	@grep -E '^[0-9a-zA-Z_-]+:(.*?## .*)?$$' $(MAKEFILE_LIST) | sed 's/^Makefile://' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

run="."
dir="./..."
short="-short"
flags=""
timeout=40s
build_tag=$(shell git describe --abbrev=0 --tags)
current_sha=$(shell git rev-parse --short HEAD)

TARGET=$(shell git describe --abbrev=0 --tags)
RELEADE_NAME=figurine
DEPLOY_FOLDER=deploy
CHECKSUM_FILE=CHECKSUM
MAKEFLAGS += -j1

.PHONY: install
install: ## Install the binary.
	@go install -trimpath -ldflags="-s -w -X main.version=$(build_tag) -X main.currentSha=$(current_sha)"

.PHONY: unittest
unittest: ## Run unit tests in watch mode. You can set: [run, timeout, short, dir, flags]. Example: make unittest flags="-race".
	@echo "running tests on $(run). waiting for changes..."
	@-zsh -c "go test -trimpath --timeout=$(timeout) $(short) $(dir) -run $(run) $(flags); repeat 100 printf '#'; echo"
	@reflex -d none -r "(\.go$$)|(go.mod)" -- zsh -c "go test -trimpath --timeout=$(timeout) $(short) $(dir) -run $(run) $(flags); repeat 100 printf '#'"

.PHONY: lint
lint: ## Run linters.
	go fmt ./...
	go vet ./...
	golangci-lint run ./...

.PHONY: dependencies
dependencies: ## Install dependencies requried for development operations.
	@go install github.com/cespare/reflex@latest
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@go install github.com/psampaz/go-mod-outdated@latest
	@go install github.com/jondot/goweight@latest
	@go get -t -u golang.org/x/tools/cmd/cover
	@go get -t -u github.com/sonatype-nexus-community/nancy@latest
	@go get -u ./...
	@go mod tidy

.PHONY: clean
clean: ## Clean test caches and tidy up modules.
	@go clean -testcache
	@go mod tidy
	@rm -rf $(DEPLOY_FOLDER)

.PHONY: tmpfolder
tmpfolder: ## Create the temporary folder.
	@mkdir -p $(DEPLOY_FOLDER)
	@rm -rf $(DEPLOY_FOLDER)/$(CHECKSUM_FILE) 2> /dev/null

.PHONY: linux-amd64
linux-amd64: tmpfolder
linux-amd64: ## Build for GNU/Linux amd64
	@GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=$(build_tag) -X main.currentSha=$(current_sha)" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME) .
	@tar -czf $(DEPLOY_FOLDER)/figurine_linux_amd64_$(TARGET).tar.gz $(DEPLOY_FOLDER)/$(RELEADE_NAME)
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_linux_amd64_$(TARGET).tar.gz >> $(CHECKSUM_FILE)
	@echo "Linux target:" $(DEPLOY_FOLDER)/figurine_linux_amd64_$(TARGET).tar.gz
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME)

.PHONY: linux-arm64
linux-arm64: tmpfolder
linux-arm64: ## Build for GNU/Linux arm64
	@GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=$(build_tag) -X main.currentSha=$(current_sha)" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME) .
	@tar -czf $(DEPLOY_FOLDER)/figurine_linux_arm64_$(TARGET).tar.gz $(DEPLOY_FOLDER)/$(RELEADE_NAME)
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_linux_arm64_$(TARGET).tar.gz >> $(CHECKSUM_FILE)
	@echo "Linux target:" $(DEPLOY_FOLDER)/figurine_linux_arm64_$(TARGET).tar.gz
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME)

.PHONY: linux-arm
linux-arm: tmpfolder
linux-arm: ## Build for GNU/Linux arm
	@GOOS=linux GOARCH=arm CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=$(build_tag) -X main.currentSha=$(current_sha)" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME) .
	@tar -czf $(DEPLOY_FOLDER)/figurine_linux_arm_$(TARGET).tar.gz $(DEPLOY_FOLDER)/$(RELEADE_NAME)
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_linux_arm_$(TARGET).tar.gz >> $(CHECKSUM_FILE)
	@echo "Linux target:" $(DEPLOY_FOLDER)/figurine_linux_arm_$(TARGET).tar.gz
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME)

.PHONY: darwin-amd64
darwin-amd64: tmpfolder
darwin-amd64: ## Build for Intel Mac.
	@GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=$(build_tag) -X main.currentSha=$(current_sha)" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME) .
	@tar -czf $(DEPLOY_FOLDER)/figurine_darwin_amd64_$(TARGET).tar.gz $(DEPLOY_FOLDER)/$(RELEADE_NAME)
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_darwin_amd64_$(TARGET).tar.gz >> $(CHECKSUM_FILE)
	@echo "Darwin target:" $(DEPLOY_FOLDER)/figurine_darwin_amd64_$(TARGET).tar.gz
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME)

.PHONY: darwin-arm64
darwin-arm64: tmpfolder
darwin-arm64: ## Build for Apple Silicon Mac.
	@GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=$(build_tag) -X main.currentSha=$(current_sha)" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME) .
	@tar -czf $(DEPLOY_FOLDER)/figurine_darwin_arm64_$(TARGET).tar.gz $(DEPLOY_FOLDER)/$(RELEADE_NAME)
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_darwin_arm64_$(TARGET).tar.gz >> $(CHECKSUM_FILE)
	@echo "Darwin target:" $(DEPLOY_FOLDER)/figurine_darwin_arm64_$(TARGET).tar.gz
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME)

.PHONY: windows-amd64
windows-amd64: tmpfolder
windows-amd64: ## Build for windoze amd64
	@GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=$(build_tag) -X main.currentSha=$(current_sha)" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe .
	@zip -r $(DEPLOY_FOLDER)/figurine_windows_amd64_$(TARGET).zip $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_windows_amd64_$(TARGET).zip >> $(CHECKSUM_FILE)
	@echo "Windows target:" $(DEPLOY_FOLDER)/figurine_windows_amd64_$(TARGET).zip
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe

.PHONY: windows-arm64
windows-arm64: tmpfolder
windows-arm64: ## Build for windoze arm64
	@GOOS=windows GOARCH=arm64 CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=$(build_tag) -X main.currentSha=$(current_sha)" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe .
	@zip -r $(DEPLOY_FOLDER)/figurine_windows_arm64_$(TARGET).zip $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_windows_arm64_$(TARGET).zip >> $(CHECKSUM_FILE)
	@echo "Windows target:" $(DEPLOY_FOLDER)/figurine_windows_arm64_$(TARGET).zip
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe


.PHONY: release
release: ## Create releases for Linux, Mac, and windoze.
release: linux-amd64 linux-arm64 linux-arm darwin-arm64 darwin-amd64 windows-amd64 windows-arm64

.PHONY: coverage
coverage: ## Show the test coverage on browser.
	go test -covermode=count -coverprofile=coverage.out ./...
	go tool cover -func=coverage.out | tail -n 1
	go tool cover -html=coverage.out

.PHONY: audit
audit: ## Audit the code for updates, vulnerabilities and binary weight.
	go list -u -m -json all | go-mod-outdated -update -direct
	go list -json -deps | nancy sleuth
	goweight | head -n 20
