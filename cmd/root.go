// Copyright 2016 Arsham Shirvani <arshamshirvani@gmail.com>. All rights reserved.
// Use of this source code is governed by the Apache 2.0 license
// License can be found in the LICENSE file.

package cmd

import (
	"bytes"
	"fmt"
	"log"
	"math/rand"
	"os"
	"strings"
	"time"

	// registers the binary data
	_ "github.com/arsham/figurine/statik"
	"github.com/arsham/rainbow/rainbow"
	figure "github.com/common-nighthawk/go-figure"
	"github.com/rakyll/statik/fs"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	cfgFile       string
	defaultString = "Arsham"
	fontName      string
	visualMode    bool
	list          bool
	sample        bool
)

var rootCmd = &cobra.Command{
	Use:   "figurine",
	Short: "Print any text in style",
	Run: func(cmd *cobra.Command, args []string) {
		if list {
			listFonts()
			return
		}
		decorate(strings.Join(args, " "))
	},
}

// Execute adds all child commands to the root command and sets flags
// appropriately.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
	rand.Seed(time.Now().UnixNano())
	cobra.OnInitialize(func() {
		viper.AutomaticEnv()
	})
	rootCmd.Flags().BoolVarP(&visualMode, "visual", "v", false, "Prints the font name.")
	rootCmd.Flags().StringVarP(&fontName, "font", "f", "", "Choose a font name. Default is a random font.")
	rootCmd.Flags().BoolVarP(&list, "list", "l", false, "Lists all available fonts.")
	rootCmd.Flags().BoolVarP(&sample, "sample", "s", false, "Prints a sample with that font.")
}

func decorate(input string) {
	if input == "" {
		input = defaultString
	}

	if fontName == "" {
		fontName = fontNames[rand.Intn(len(fontNames))]
	}

	if visualMode {
		fmt.Printf("Font: %s\n", fontName)
	}
	withFont(input, fontName)
}

func withFont(input, fontName string) {
	fs, err := fs.New()
	if err != nil {
		log.Fatal(err)
	}

	font, err := fs.Open(fmt.Sprintf("/%s", fontName))
	if err != nil {
		log.Fatalf("%s: %s", err, fontName)
	}
	myFigure := figure.NewFigureWithFont(input, font, true)
	buf := new(bytes.Buffer)
	figure.Write(buf, myFigure)

	seed := int(rand.Int31n(256))
	l := rainbow.Light{
		Reader: buf,
		Writer: os.Stdout,
		Seed:   seed,
	}
	if err := l.Paint(); err != nil {
		log.Fatal(err)
	}
}

func listFonts() {
	input := "Golang"
	for _, f := range fontNames {
		fmt.Println(f)
		if sample {
			withFont(input, f)
			fmt.Println()
		}
	}
}
