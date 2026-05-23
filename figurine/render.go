// Copyright 2026 Arsham Shirvani <arshamshirvani@gmail.com>. All rights reserved.
// Use of this source code is governed by the Apache 2.0 license.
// License can be found in the LICENSE file.

package figurine

import (
	"bufio"
	"fmt"
	"io"
	"strconv"
	"strings"
)

const (
	firstPrintableASCII = ' '
	lastPrintableASCII  = '~'
	asciiOffset         = 32
)

type figletFont struct {
	height    int
	baseline  int
	hardblank string
	glyphs    [][]string
}

func renderFIGlet(r io.Reader, msg string) (string, error) {
	font, err := parseFIGletFont(r)
	if err != nil {
		return "", err
	}

	rows := make([]string, font.height)
	for _, char := range msg {
		glyph := font.glyphFor(char)
		for i := range rows {
			rows[i] += strings.ReplaceAll(glyph[i], font.hardblank, " ")
		}
	}

	var out strings.Builder
	for i, row := range rows {
		if i >= font.baseline && strings.TrimSpace(row) == "" {
			continue
		}
		out.WriteString(strings.TrimRight(row, " "))
		out.WriteByte('\n')
	}
	return out.String(), nil
}

func parseFIGletFont(r io.Reader) (figletFont, error) {
	scanner := bufio.NewScanner(r)
	if !scanner.Scan() {
		return figletFont{}, fmt.Errorf("reading font header: %w", scanner.Err())
	}

	fields := strings.Fields(scanner.Text())
	if len(fields) < 6 || !strings.HasPrefix(fields[0], "flf2") {
		return figletFont{}, fmt.Errorf("invalid FIGlet font header")
	}
	if len(fields[0]) < len("flf2a") {
		return figletFont{}, fmt.Errorf("invalid FIGlet hardblank header")
	}

	height, err := strconv.Atoi(fields[1])
	if err != nil || height <= 0 {
		return figletFont{}, fmt.Errorf("invalid FIGlet font height %q", fields[1])
	}
	baseline, err := strconv.Atoi(fields[2])
	if err != nil || baseline < 0 {
		return figletFont{}, fmt.Errorf("invalid FIGlet font baseline %q", fields[2])
	}
	commentLines, err := strconv.Atoi(fields[5])
	if err != nil || commentLines < 0 {
		return figletFont{}, fmt.Errorf("invalid FIGlet font comment count %q", fields[5])
	}

	for range commentLines {
		if !scanner.Scan() {
			return figletFont{}, fmt.Errorf("reading FIGlet font comments: %w", scanner.Err())
		}
	}

	font := figletFont{
		height:    height,
		baseline:  baseline,
		hardblank: fields[0][len(fields[0])-1:],
		glyphs:    make([][]string, lastPrintableASCII-firstPrintableASCII+1),
	}
	for i := range font.glyphs {
		glyph, err := readGlyph(scanner, height)
		if err != nil {
			return figletFont{}, fmt.Errorf("reading glyph %d: %w", i+asciiOffset, err)
		}
		font.glyphs[i] = glyph
	}
	return font, scanner.Err()
}

func readGlyph(scanner *bufio.Scanner, height int) ([]string, error) {
	glyph := make([]string, height)
	width := 0
	for i := range glyph {
		if !scanner.Scan() {
			return nil, scanner.Err()
		}
		glyph[i] = trimFIGletEndmark(scanner.Text())
		if len(glyph[i]) > width {
			width = len(glyph[i])
		}
	}
	for i := range glyph {
		glyph[i] += strings.Repeat(" ", width-len(glyph[i]))
	}
	return glyph, nil
}

func trimFIGletEndmark(line string) string {
	if line == "" {
		return line
	}
	endmark := line[len(line)-1]
	line = line[:len(line)-1]
	if line != "" && line[len(line)-1] == endmark {
		line = line[:len(line)-1]
	}
	return line
}

func (font figletFont) glyphFor(char rune) []string {
	if char < firstPrintableASCII || char > lastPrintableASCII {
		char = '?'
	}
	return font.glyphs[char-asciiOffset]
}
