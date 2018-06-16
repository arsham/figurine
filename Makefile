TARGET=$(shell git describe)

deps:
	@go get github.com/Masterminds/glide
	@glide install

tmpfolder:
	mkdir -p deploy

linux: tmpfolder
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o deploy/figurine main.go
	cd deploy; tar -czf figurine_linux_$(TARGET).tar.gz figurine ; rm figurine

darwin: tmpfolder
	GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o deploy/figurine main.go
	cd deploy; tar -czf figurine_darwin_$(TARGET).tar.gz figurine ; rm figurine

windows: tmpfolder
	GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o deploy/figurine.exe main.go
	cd deploy; zip -r figurine_windows_$(TARGET).zip figurine.exe ; rm figurine.exe

release: deps linux darwin windows

clean:
	rm -rf deploy

install: deps
	go install

update: deps
	git pull origin master

.PHONY: release linux darwin windows tmpfolder clean install deps update
