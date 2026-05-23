// Copyright 2026 Arsham Shirvani <arshamshirvani@gmail.com>. All rights reserved.
// Use of this source code is governed by the Apache 2.0 license.
// License can be found in the LICENSE file.

package main

import (
	"bytes"
	"slices"
	"strings"
	"testing"
)

const testFontName = "Poison.flf"

func TestParseArgsCombinesShortBooleanFlags(t *testing.T) {
	opts, input, err := parseArgs([]string{"-ls", "Sample", "Text"})
	if err != nil {
		t.Fatalf("parse args: %v", err)
	}
	if !opts.listFonts {
		t.Fatal("list flag was not set")
	}
	if !opts.showSample {
		t.Fatal("sample flag was not set")
	}
	if !slices.Equal(input, []string{"Sample", "Text"}) {
		t.Fatalf("input = %q, want Sample Text", input)
	}
}

func TestParseArgsReadsLongFontValue(t *testing.T) {
	opts, input, err := parseArgs([]string{"--font", testFontName, "hello"})
	if err != nil {
		t.Fatalf("parse args: %v", err)
	}
	if opts.fontName != testFontName {
		t.Fatalf("font name = %q, want %s", opts.fontName, testFontName)
	}
	if !slices.Equal(input, []string{"hello"}) {
		t.Fatalf("input = %q, want hello", input)
	}
}

func TestParseArgsStopsAtSeparator(t *testing.T) {
	_, input, err := parseArgs([]string{"--", "--not-a-flag"})
	if err != nil {
		t.Fatalf("parse args: %v", err)
	}
	if !slices.Equal(input, []string{"--not-a-flag"}) {
		t.Fatalf("input = %q, want --not-a-flag", input)
	}
}

func TestParseArgsReportsUnknownFlag(t *testing.T) {
	_, _, err := parseArgs([]string{"--bogus"})
	if err == nil {
		t.Fatal("expected an error")
	}
	if !strings.Contains(err.Error(), "unknown flag --bogus") {
		t.Fatalf("error = %q, want unknown flag", err)
	}
}

func TestRunHelpWritesUsefulUsage(t *testing.T) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer

	code := run([]string{"--help"}, &stdout, &stderr)
	if code != 0 {
		t.Fatalf("exit code = %d, want 0", code)
	}
	if stderr.Len() != 0 {
		t.Fatalf("stderr = %q, want empty", stderr.String())
	}
	output := stdout.String()
	for _, want := range []string{"Usage:", "Examples:", "-ls Sample Text", "--font name"} {
		if !strings.Contains(output, want) {
			t.Fatalf("help output does not contain %q", want)
		}
	}
}

func TestListAvailableFontsHidesLegacyAliases(t *testing.T) {
	var stdout bytes.Buffer

	listAvailableFonts(&stdout, nil, false)
	output := stdout.String()
	for _, want := range []string{"AMC 3 Line.flf\n", "Big Chief.flf\n", "s-relief.flf\n"} {
		if !strings.Contains(output, want) {
			t.Fatalf("font list does not contain %q", want)
		}
	}
	for _, unwanted := range []string{"3d.flf", "amc3line.flf", "bigchief.flf", "broadway_kb.flf"} {
		if strings.Contains(output, unwanted) {
			t.Fatalf("font list contains legacy alias %q", unwanted)
		}
	}
}

func TestDecorateAcceptsLegacyFontAliases(t *testing.T) {
	var stdout bytes.Buffer

	err := decorate(&stdout, "hello", "amc3line.flf", true)
	if err != nil {
		t.Fatalf("decorate with legacy font alias: %v", err)
	}
	if !strings.Contains(stdout.String(), "Font: AMC 3 Line.flf\n") {
		t.Fatalf("visual output did not use canonical font name: %q", stdout.String())
	}
}

func TestDecorateAcceptsCanonicalFontNames(t *testing.T) {
	var stdout bytes.Buffer

	err := decorate(&stdout, "hello", "AMC 3 Line.flf", true)
	if err != nil {
		t.Fatalf("decorate with canonical font name: %v", err)
	}
	if !strings.Contains(stdout.String(), "Font: AMC 3 Line.flf\n") {
		t.Fatalf("visual output did not use canonical font name: %q", stdout.String())
	}
}
