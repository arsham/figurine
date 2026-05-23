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

func TestRenderFIGletPreservesLatin1FontBytes(t *testing.T) {
	font := testFontBytes(map[rune][][]byte{
		'A': {[]byte{'A', 0xb4, 'A'}, []byte{'A'}, []byte{'A'}},
	})

	got, err := renderFIGlet(strings.NewReader(string(font)), "A")
	if err != nil {
		t.Fatalf("render FIGlet: %v", err)
	}

	want := "A´A\nA\nA\n"
	if got != want {
		t.Fatalf("rendered output = %q, want %q", got, want)
	}
}

func TestRenderFIGletPreservesUTF8FontRows(t *testing.T) {
	font := testFont(map[rune][]string{
		'A': {"A\u00a0A", "A", "A"},
	})

	got, err := renderFIGlet(strings.NewReader(font), "A")
	if err != nil {
		t.Fatalf("render FIGlet: %v", err)
	}

	if strings.Contains(got, "Â") {
		t.Fatalf("rendered output mojibaked UTF-8 bytes: %q", got)
	}
	if !strings.Contains(got, "A\u00a0A") {
		t.Fatalf("rendered output did not preserve UTF-8 row: %q", got)
	}
}

func TestRenderFIGletRendersStrongerThanAllWithoutMojibake(t *testing.T) {
	font, err := fonts.Open("fonts/Stronger Than All.flf")
	if err != nil {
		t.Fatalf("open font: %v", err)
	}

	got, err := renderFIGlet(font, "Arsham")
	if err != nil {
		t.Fatalf("render FIGlet: %v", err)
	}
	if strings.Contains(got, "Â") {
		t.Fatalf("rendered output contains mojibake: %q", got)
	}
}

func TestRenderFIGletRendersKontoWithoutReplacementCharacters(t *testing.T) {
	for _, fontName := range []string{"Konto.flf", "Konto Slant.flf"} {
		fontName := fontName
		t.Run(fontName, func(t *testing.T) {
			font, err := fonts.Open("fonts/" + fontName)
			if err != nil {
				t.Fatalf("open font: %v", err)
			}

			got, err := renderFIGlet(font, "Arsham")
			if err != nil {
				t.Fatalf("render FIGlet: %v", err)
			}
			if strings.Contains(got, "�") {
				t.Fatalf("rendered output contains replacement character: %q", got)
			}
		})
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

func testFontBytes(overrides map[rune][][]byte) []byte {
	const height = 3

	var out []byte
	out = append(out, []byte("flf2$ 3 2 3 -1 0\n")...)
	for char := firstPrintableASCII; char <= lastPrintableASCII; char++ {
		glyph, ok := overrides[char]
		if !ok {
			glyph = [][]byte{{}, {}, {}}
		}
		for row := range height {
			out = append(out, glyph[row]...)
			out = append(out, '@')
			if row == height-1 {
				out = append(out, '@')
			}
			out = append(out, '\n')
		}
	}
	return out
}
