// Copyright 2018 Arsham Shirvani <arshamshirvani@gmail.com>. All rights reserved.
// Use of this source code is governed by the Apache 2.0 license
// License can be found in the LICENSE file.

package figurine

import (
	"bytes"
	"fmt"
	"io"
	"math/rand"

	"github.com/arsham/rainbow/rainbow"
	figure "github.com/common-nighthawk/go-figure"
	"github.com/pkg/errors"
	"github.com/rakyll/statik/fs"
)

// Write loads fontName and writes the msg decorated by rainbow with the font
// into out.
func Write(out io.Writer, msg, fontName string) error {
	fs, err := fs.New()
	if err != nil {
		return err
	}
	font, err := fs.Open(fmt.Sprintf("/%s", fontName))
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
	if _, err := io.Copy(l, buf); err != nil {
		return err
	}
	return nil
}
