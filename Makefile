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
LINUX_ARCH = amd64 arm arm64
DARWIN_ARCH = amd64 arm64
WINDOWS_ARCH = amd64 arm64
LDFLAGS = -s -w -X main.version=$(build_tag) -X main.currentSha=$(current_sha)

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
	golangci-lint fmt
	go vet ./...
	golangci-lint run ./...

.PHONY: dependencies
dependencies: ## Install dependencies required for development operations.
	@go install github.com/cespare/reflex@latest
	@go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
	@go install github.com/psampaz/go-mod-outdated@latest
	@go install github.com/jondot/goweight@latest
	@go install golang.org/x/vuln/cmd/govulncheck@latest
	@go mod tidy

.PHONY: upgrade
upgrade: ## Upgrade module dependencies to latest compatible versions.
	@go get -u -t ./...
	@go mod tidy

.PHONY: clean
clean: ## Clean test caches and tidy up modules.
	@go clean -testcache
	@go mod tidy
	@rm -rf $(DEPLOY_FOLDER)

.PHONY: tmpfolder
tmpfolder: ## Create the temporary folder.
	@mkdir -p $(DEPLOY_FOLDER)

.PHONY: reset-checksum
reset-checksum: tmpfolder ## Reset the release checksum file.
	@rm -rf $(DEPLOY_FOLDER)/$(CHECKSUM_FILE) 2> /dev/null

define build_unix_target
.PHONY: $(1)-$(2)
$(1)-$(2): tmpfolder
	@GOOS=$(1) GOARCH=$(2) CGO_ENABLED=0 go build -trimpath -ldflags="$(LDFLAGS)" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME) .
	@tar -czf $(DEPLOY_FOLDER)/figurine_$(1)_$(2)_$(TARGET).tar.gz $(DEPLOY_FOLDER)/$(RELEADE_NAME)
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_$(1)_$(2)_$(TARGET).tar.gz >> $(CHECKSUM_FILE)
	@echo "$(1) target:" $(DEPLOY_FOLDER)/figurine_$(1)_$(2)_$(TARGET).tar.gz
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME)
endef

define build_windows_target
.PHONY: windows-$(1)
windows-$(1): tmpfolder
	@GOOS=windows GOARCH=$(1) CGO_ENABLED=0 go build -trimpath -ldflags="$(LDFLAGS)" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe .
	@zip -r $(DEPLOY_FOLDER)/figurine_windows_$(1)_$(TARGET).zip $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_windows_$(1)_$(TARGET).zip >> $(CHECKSUM_FILE)
	@echo "windows target:" $(DEPLOY_FOLDER)/figurine_windows_$(1)_$(TARGET).zip
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe
endef

$(foreach arch,$(LINUX_ARCH),$(eval $(call build_unix_target,linux,$(arch))))
$(foreach arch,$(DARWIN_ARCH),$(eval $(call build_unix_target,darwin,$(arch))))
$(foreach arch,$(WINDOWS_ARCH),$(eval $(call build_windows_target,$(arch))))

.PHONY: linux
linux: $(addprefix linux-,$(LINUX_ARCH)) ## Build for GNU/Linux.

.PHONY: $(LINUX_ARCH)
$(LINUX_ARCH): %: linux-% ## Build for GNU/Linux by architecture.

.PHONY: darwin
darwin: $(addprefix darwin-,$(DARWIN_ARCH)) ## Build for Mac.

.PHONY: windows
windows: $(addprefix windows-,$(WINDOWS_ARCH)) ## Build for windoze.

.PHONY: release
release: ## Create releases for Linux, Mac, and windoze.
release: reset-checksum linux darwin windows

.PHONY: coverage
coverage: ## Show the test coverage on browser.
	go test -covermode=count -coverprofile=coverage.out ./...
	go tool cover -func=coverage.out | tail -n 1
	go tool cover -html=coverage.out

.PHONY: audit
audit: ## Audit the code for updates, vulnerabilities and binary weight.
	go list -u -m -json all | go-mod-outdated -update -direct
	govulncheck ./...
	goweight | head -n 20
