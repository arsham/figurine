# Figurine

[![PkgGoDev](https://pkg.go.dev/badge/github.com/arsham/figurine)](https://pkg.go.dev/github.com/arsham/figurine)
![GitHub go.mod Go version](https://img.shields.io/github/go-mod/go-version/arsham/figurine)
[![Go Report Card](https://goreportcard.com/badge/github.com/arsham/figurine)](https://goreportcard.com/report/github.com/arsham/figurine)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Print your name in style

![Screenshot](/docs/figurine.png?raw=true "Rainbow")

### Table of Contents

1. [Installation](#installation)
2. [Usage](#usage)
3. [Docker](#docker)
4. [Building from Source](#building-from-source)
5. [Creating Releases](#creating-releases)
6. [See Also](#see-also)
7. [License](#license)

## Installation

You can download the latest binary from
[here](https://github.com/arsham/figurine/releases), or you can compile from
source:

```bash
go install github.com/arsham/figurine@latest
```

## Usage

Every time the application is called, it chooses a random font for rendering the
message. Pass the message you want to decorate as arguments.

```bash
figurine Some Text
```

You can print available fonts:

```bash
figurine -l
figurine -l -s
figurine -ls Sample Text
```

To set a font:

```bash
figurine -f "Poison.flf" Some Text
```

To get a list of available arguments:

```bash
figurine -h
```

This application is very light weight, so feel free to add it to your
.zshrc/.bashrc file, so each time you open a new shell it shows you a nice
message.

## Docker

To build the Docker image:

```bash
make docker-build
```

To run the Docker container:

```bash
make docker-run
```

To build multi-platform Docker images (requires Docker Buildx):

```bash
make docker-buildx
```

To clean up the Docker image and container:

```bash
make docker-clean
```

## Building from Source

### Local Development Build

To build the project for your local machine:

```bash
make build
```

### Cross-Platform Builds

To build for multiple platforms (Linux, macOS, Windows):

```bash
make build-all
```

This creates binaries in the `dist` folder for the following platforms:
- Linux (amd64, arm64)
- macOS (amd64, arm64)
- Windows (amd64)

Each binary is compressed into a tar.gz archive with platform-specific naming.

## Creating Releases

### Manual Release

1. Build all platform binaries:
   ```bash
   make release
   ```
   
2. This will create compressed archives and a checksums.txt file in the `dist` folder.

### Automated Release

Releases are automated using GitHub Actions. To create a new release:

1. Tag the commit with a version number:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. GitHub Actions will automatically:
   - Build binaries for all supported platforms
   - Create a new GitHub Release with the binaries
   - Build and push Docker images to Docker Hub (if configured)

## See Also

See also [Rainbow][rainbow], which is the library that colours the output.

## License

Use of this source code is governed by the Apache 2.0 license. License that can
be found in the [LICENSE](./LICENSE) file.

[rainbow]: https://github.com/arsham/rainbow
