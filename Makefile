TARGET=$(shell git describe --abbrev=0 --tags)
RELEADE_NAME=figurine
DEPLOY_FOLDER=deploy
CHECKSUM_FILE=CHECKSUM

.PHONY: install
install: ## Install the binary.
	@go install -trimpath -ldflags="-s -w"

.PHONY: test
test:
	@zsh -c "go test ./...; repeat 100 printf '#'; echo"
	@reflex -d none -r "\.go$$" -- zsh -c "go test ./...; repeat 100 printf '#'"

.PHONY: tmpfolder
tmpfolder:
	@mkdir -p $(DEPLOY_FOLDER)
	@rm -rf $(DEPLOY_FOLDER)/$(CHECKSUM_FILE) 2> /dev/null

.PHONY: linux
linux: tmpfolder
linux: ## Build for GNU/Linux.
	@GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME) .
	@tar -czf $(DEPLOY_FOLDER)/figurine_linux_$(TARGET).tar.gz $(DEPLOY_FOLDER)/$(RELEADE_NAME)
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_linux_$(TARGET).tar.gz >> $(CHECKSUM_FILE)
	@echo "Linux target:" $(DEPLOY_FOLDER)/figurine_linux_$(TARGET).tar.gz
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME)

.PHONY: darwin
darwin: tmpfolder
darwin: ## Build for Mac.
	@GOOS=darwin GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME) .
	@tar -czf $(DEPLOY_FOLDER)/figurine_darwin_$(TARGET).tar.gz $(DEPLOY_FOLDER)/$(RELEADE_NAME)
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_darwin_$(TARGET).tar.gz >> $(CHECKSUM_FILE)
	@echo "Darwin target:" $(DEPLOY_FOLDER)/figurine_darwin_$(TARGET).tar.gz
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME)

.PHONY: windows
windows: tmpfolder
windows: ## Build for windoze.
	@GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe .
	@zip -r $(DEPLOY_FOLDER)/figurine_windows_$(TARGET).zip $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_windows_$(TARGET).zip >> $(CHECKSUM_FILE)
	@echo "Windows target:" $(DEPLOY_FOLDER)/figurine_windows_$(TARGET).zip
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe

.PHONY: release
release: tmpfolder linux darwin windows

.PHONY: clean
clean:
	go clean
	go clean -cache
	go clean -modcache
	rm -rf $(DEPLOY_FOLDER)
