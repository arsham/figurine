// Copyright 2026 Arsham Shirvani <arshamshirvani@gmail.com>. All rights reserved.
// Use of this source code is governed by the Apache 2.0 license.
// License can be found in the LICENSE file.

package figurine

import (
	"fmt"
	"strings"
	"testing"
)

func TestRenderFIGletPadsShortGlyphRows(t *testing.T) {
	font := testFont(map[rune][]string{
		'A': {"A", "A", "A"},
		'-': {"", "--", ""},
		'B': {"B", "B", "B"},
	})

	got, err := renderFIGlet(strings.NewReader(font), "A-B")
	if err != nil {
		t.Fatalf("render FIGlet: %v", err)
	}

	want := "A  B\nA--B\nA  B\n"
	if got != want {
		t.Fatalf("rendered output = %q, want %q", got, want)
	}
}

func TestRenderFIGletReplacesHardblanks(t *testing.T) {
	const glyphRow = "A$A"

	font := testFont(map[rune][]string{
		'A': {glyphRow, glyphRow, glyphRow},
	})

	got, err := renderFIGlet(strings.NewReader(font), "A")
	if err != nil {
		t.Fatalf("render FIGlet: %v", err)
	}

	want := "A A\nA A\nA A\n"
	if got != want {
		t.Fatalf("rendered output = %q, want %q", got, want)
	}
}

func TestRenderFIGletUsesQuestionMarkForUnsupportedRunes(t *testing.T) {
	font := testFont(map[rune][]string{
		'?': {"?", "?", "?"},
	})

	got, err := renderFIGlet(strings.NewReader(font), "é")
	if err != nil {
		t.Fatalf("render FIGlet: %v", err)
	}

	want := "?\n?\n?\n"
	if got != want {
		t.Fatalf("rendered output = %q, want %q", got, want)
	}
}

func TestRenderFIGletRejectsInvalidHeader(t *testing.T) {
	_, err := renderFIGlet(strings.NewReader("not a font\n"), "A")
	if err == nil {
		t.Fatal("expected invalid header error")
	}
}

func testFont(overrides map[rune][]string) string {
	const height = 3

	var out strings.Builder
	out.WriteString("flf2$ 3 2 3 -1 0\n")
	for char := firstPrintableASCII; char <= lastPrintableASCII; char++ {
		glyph, ok := overrides[char]
		if !ok {
			glyph = []string{"", "", ""}
		}
		for row := range height {
			endmark := "@"
			if row == height-1 {
				endmark = "@@"
			}
			_, _ = fmt.Fprintf(&out, "%s%s\n", glyph[row], endmark)
		}
	}
	return out.String()
}
