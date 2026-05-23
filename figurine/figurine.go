// Copyright 2018 Arsham Shirvani <arshamshirvani@gmail.com>. All rights reserved.
// Use of this source code is governed by the Apache 2.0 license.
// License can be found in the LICENSE file.

// Package figurine contains functionality to print an input with style.
package figurine

import (
	"bytes"
	"embed"
	"fmt"
	"io"
	"math/rand/v2"
	"path"

	"github.com/arsham/rainbow/v2/rainbow"
)

//go:embed fonts
var fonts embed.FS

// Write loads fontName and writes the msg decorated by rainbow with the font
// into out.
func Write(out io.Writer, msg, fontName string) error {
	font, err := fonts.Open(path.Join("fonts/", fontName))
	if err != nil {
		return fmt.Errorf("error locating font %s: %w", fontName, err)
	}

	figletOutput, err := renderFIGlet(font, msg)
	if err != nil {
		return fmt.Errorf("error rendering font %s: %w", fontName, err)
	}
	buf := bytes.NewBufferString(figletOutput)
	l := &rainbow.Light{
		Writer: out,
		Seed:   rand.Int64N(256),
	}
	_, err = io.Copy(l, buf)
	return err
}
