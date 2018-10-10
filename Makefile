TARGET=$(shell git describe --abbrev=0 --tags)
RELEADE_NAME=figurine
DEPLOY_FOLDER=deploy
CHECKSUM_FILE=CHECKSUM

.PHONY: deps
deps:
	@go get github.com/Masterminds/glide
	@glide install

.PHONY: tmpfolder
tmpfolder:
	@mkdir -p $(DEPLOY_FOLDER)
	@rm -rf $(DEPLOY_FOLDER)/$(CHECKSUM_FILE) 2> /dev/null

.PHONY: linux
linux: tmpfolder
	@GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME) main.go
	@tar -czf $(DEPLOY_FOLDER)/figurine_linux_$(TARGET).tar.gz $(DEPLOY_FOLDER)/$(RELEADE_NAME)
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_linux_$(TARGET).tar.gz >> $(CHECKSUM_FILE)
	@echo "Linux target:" $(DEPLOY_FOLDER)/figurine_linux_$(TARGET).tar.gz
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME)

.PHONY: darwin
darwin: tmpfolder
	@GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME) main.go
	@tar -czf $(DEPLOY_FOLDER)/figurine_darwin_$(TARGET).tar.gz $(DEPLOY_FOLDER)/$(RELEADE_NAME)
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_darwin_$(TARGET).tar.gz >> $(CHECKSUM_FILE)
	@echo "Darwin target:" $(DEPLOY_FOLDER)/figurine_darwin_$(TARGET).tar.gz
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME)

.PHONY: windows
windows: tmpfolder
	@GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe main.go
	@zip -r $(DEPLOY_FOLDER)/figurine_windows_$(TARGET).zip $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe
	@cd $(DEPLOY_FOLDER) ; sha256sum figurine_windows_$(TARGET).zip >> $(CHECKSUM_FILE)
	@echo "Darwin target:" $(DEPLOY_FOLDER)/figurine_windows_$(TARGET).zip
	@rm $(DEPLOY_FOLDER)/$(RELEADE_NAME).exe

.PHONY: release
release: tmpfolder deps linux darwin windows

.PHONY: clean
clean:
	rm -rf $(DEPLOY_FOLDER)

.PHONY: install
install: deps
	go install

.PHONY: update
update: deps
	git pull origin master
