# Figurine

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![GoDoc](https://godoc.org/github.com/arsham/figurine?status.svg)](http://godoc.org/github.com/arsham/figurine)
[![Go Report Card](https://goreportcard.com/badge/github.com/arsham/figurine)](https://goreportcard.com/report/github.com/arsham/figurine)

Print your name in style

![Screenshot](/docs/figurine.png?raw=true "Rainbow")

### Table of Contents

1. [Installation](#installation)
2. [Usage](#usage)
3. [See Also](#see-also)
4. [License](#license)

## Installation

Get the library:
```bash
$ go get github.com/arsham/figurine
$ glide install
$ go install
```

## Usage

Every time the application is called, it chooses a random font for rendering the
message. Pass the message you want to decorate as arguments.

```bash
$ figurine Arsham
```

This application is very light weight, so feel free to add it to your
.zshrc/.bashrc file, so each time you open a new shell it shows you a nice
message.

## See Also
See also [Rainbow][rainbow], which is the library that colours the output.

## License
Use of this source code is governed by the Apache 2.0 license. License that can
be found in the [LICENSE](./LICENSE) file.

[rainbow]: https://github.com/arsham/rainbow
