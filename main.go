// Copyright 2016 Arsham Shirvani <arshamshirvani@gmail.com>. All rights reserved.
// Use of this source code is governed by the Apache 2.0 license.
// License can be found in the LICENSE file.

// Package main is the entrypoint to the figurine binary.
package main

import (
	"fmt"
	"io"
	"math/rand/v2"
	"os"
	"strings"

	"github.com/arsham/figurine/v2/figurine"
)

const defaultString = "Arsham"

var (
	version    = "development"
	currentSha = "N/A"
)

type options struct {
	fontName    string
	visualMode  bool
	listFonts   bool
	showSample  bool
	showHelp    bool
	showVersion bool
}

func main() {
	os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
}

func run(args []string, stdout, stderr io.Writer) int {
	opts, input, err := parseArgs(args)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "figurine: %v\n\n", err)
		printUsage(stderr)
		return 2
	}

	if opts.showHelp || (!opts.listFonts && firstArg(input, "help")) {
		printUsage(stdout)
		return 0
	}
	if opts.listFonts {
		listAvailableFonts(stdout, input, opts.showSample)
		return 0
	}
	if opts.showVersion || firstArg(input, "version") {
		printVersion(stdout)
		return 0
	}
	if err := decorate(stdout, strings.Join(input, " "), opts.fontName, opts.visualMode); err != nil {
		_, _ = fmt.Fprintf(stderr, "figurine: %v\n", err)
		return 1
	}
	return 0
}

func parseArgs(args []string) (options, []string, error) {
	var opts options
	input := make([]string, 0, len(args))

	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch {
		case arg == "--":
			input = append(input, args[i+1:]...)
			return opts, input, nil
		case strings.HasPrefix(arg, "--") && len(arg) > 2:
			if err := parseLongFlag(args, &i, &opts); err != nil {
				return opts, nil, err
			}
		case strings.HasPrefix(arg, "-") && arg != "-":
			if err := parseShortFlags(args, &i, &opts); err != nil {
				return opts, nil, err
			}
		default:
			input = append(input, arg)
		}
	}

	return opts, input, nil
}

func parseLongFlag(args []string, index *int, opts *options) error {
	name, value, hasValue := strings.Cut(args[*index][2:], "=")
	switch name {
	case "help":
		if hasValue {
			return fmt.Errorf("flag --help does not take a value")
		}
		opts.showHelp = true
	case "version":
		if hasValue {
			return fmt.Errorf("flag --version does not take a value")
		}
		opts.showVersion = true
	case "visual":
		if hasValue {
			return fmt.Errorf("flag --visual does not take a value")
		}
		opts.visualMode = true
	case "list":
		if hasValue {
			return fmt.Errorf("flag --list does not take a value")
		}
		opts.listFonts = true
	case "sample":
		if hasValue {
			return fmt.Errorf("flag --sample does not take a value")
		}
		opts.showSample = true
	case "font":
		fontName, err := flagValue(args, index, value, hasValue)
		if err != nil {
			return err
		}
		opts.fontName = fontName
	default:
		return fmt.Errorf("unknown flag --%s", name)
	}
	return nil
}

func parseShortFlags(args []string, index *int, opts *options) error {
	flags := args[*index][1:]
	for pos := 0; pos < len(flags); pos++ {
		switch flags[pos] {
		case 'h':
			opts.showHelp = true
		case 'v':
			opts.visualMode = true
		case 'l':
			opts.listFonts = true
		case 's':
			opts.showSample = true
		case 'f':
			fontName, err := shortFlagValue(args, index, flags, pos)
			if err != nil {
				return err
			}
			opts.fontName = fontName
			return nil
		default:
			return fmt.Errorf("unknown flag -%c", flags[pos])
		}
	}
	return nil
}

func shortFlagValue(args []string, index *int, flags string, pos int) (string, error) {
	if pos+1 < len(flags) {
		return validateFontName(flags[pos+1:])
	}
	next := *index + 1
	if next >= len(args) {
		return "", fmt.Errorf("missing value for -f")
	}
	*index = next
	return validateFontName(args[next])
}

func flagValue(args []string, index *int, value string, hasValue bool) (string, error) {
	if hasValue {
		return validateFontName(value)
	}
	next := *index + 1
	if next >= len(args) {
		return "", fmt.Errorf("missing value for --font")
	}
	*index = next
	return validateFontName(args[next])
}

func validateFontName(fontName string) (string, error) {
	if fontName == "" {
		return "", fmt.Errorf("font name cannot be empty")
	}
	return fontName, nil
}

func firstArg(args []string, value string) bool {
	return len(args) > 0 && args[0] == value
}

func printUsage(w io.Writer) {
	_, _ = fmt.Fprint(w, `Figurine prints text in a random FIGlet font with rainbow colours.

Usage:
  figurine [flags] [text...]
  figurine help
  figurine version

Examples:
  figurine Some Text
  figurine -f "Poison.flf" Some Text
  figurine -l
  figurine -ls Sample Text
  figurine -- --text starting with a dash

Flags:
  -f, --font name   Use a specific font (default: random)
  -l, --list        List available fonts
  -s, --sample      With --list, print a sample for each font
  -v, --visual      Print the selected font name before output
      --version     Print binary version information
  -h, --help        Show this help

When text is omitted, figurine prints "Arsham".
Short boolean flags can be combined, such as -ls.
`)
}

func printVersion(w io.Writer) {
	_, _ = fmt.Fprintf(w, "figurine version %s (%s)\n", version, currentSha)
}

func decorate(out io.Writer, input, fontName string, visualMode bool) error {
	if input == "" {
		input = defaultString
	}
	if fontName == "" {
		index := rand.IntN(len(fontNames))
		fontName = fontNames[index]
	} else {
		fontName = canonicalFontName(fontName)
	}
	if visualMode {
		_, _ = fmt.Fprintf(out, "Font: %s\n", fontName)
	}
	return figurine.Write(out, input, fontName)
}

func canonicalFontName(fontName string) string {
	if canonicalName, ok := fontAliases[fontName]; ok {
		return canonicalName
	}
	return fontName
}

func listAvailableFonts(out io.Writer, args []string, sample bool) {
	if len(args) == 0 {
		args = []string{"Golang"}
	}
	input := strings.Join(args, " ")
	for _, f := range fontNames {
		_, _ = fmt.Fprintln(out, f)
		if sample {
			err := figurine.Write(out, input, f)
			if err != nil {
				_, _ = fmt.Fprintf(os.Stderr, "printing to the output: %v", err)
			}
			_, _ = fmt.Fprintln(out)
		}
	}
}
