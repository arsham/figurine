// Copyright 2018 Arsham Shirvani <arshamshirvani@gmail.com>. All rights reserved.
// Use of this source code is governed by the Apache 2.0 license.
// License can be found in the LICENSE file.

// Package figurine contains functionality to print an input with style.
package figurine

import (
	"bytes"
	"embed"
	"io"
	"math/rand"
	"path"

	"github.com/arsham/rainbow/rainbow"
	figure "github.com/common-nighthawk/go-figure"
	"github.com/pkg/errors"
)

//go:embed fonts
var fonts embed.FS

// Write loads fontName and writes the msg decorated by rainbow with the font
// into out.
func Write(out io.Writer, msg, fontName string) error {
	font, err := fonts.Open(path.Join("fonts/", fontName))
	if err != nil {
		return errors.Wrap(err, fontName)
	}

	buf := &bytes.Buffer{}
	myFigure := figure.NewFigureWithFont(msg, font, true)
	figure.Write(buf, myFigure)
	l := &rainbow.Light{
		Writer: out,
		Seed:   rand.Int63n(256),
	}
	_, err = io.Copy(l, buf)
	return err
}
