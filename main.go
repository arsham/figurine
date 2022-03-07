// Copyright 2016 Arsham Shirvani <arshamshirvani@gmail.com>. All rights reserved.
// Use of this source code is governed by the Apache 2.0 license.
// License can be found in the LICENSE file.

package main

import (
	"fmt"
	"math/rand"
	"os"
	"strings"
	"time"

	"github.com/arsham/figurine/figurine"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	defaultString = "Arsham"
	fontName      string
	visualMode    bool
	list          bool
	sample        bool
)

var rootCmd = &cobra.Command{
	Use:   "figurine",
	Short: "Print any text in style",
	RunE: func(_ *cobra.Command, args []string) error {
		if list {
			listFonts()
			return nil
		}
		return decorate(strings.Join(args, " "))
	},
}

//go:generate statik -f -src=./bin ; go fmt ./statik/statik.go
func main() {
	cobra.CheckErr(rootCmd.Execute())
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

func decorate(input string) error {
	if input == "" {
		input = defaultString
	}
	if fontName == "" {
		index := rand.Intn(len(fontNames))
		fontName = fontNames[index]
	}
	if visualMode {
		fmt.Printf("Font: %s\n", fontName)
	}
	return figurine.Write(os.Stdout, input, fontName)
}

func listFonts() {
	input := "Golang"
	for _, f := range fontNames {
		fmt.Println(f)
		if sample {
			err := figurine.Write(os.Stdout, input, f)
			if err != nil {
				fmt.Fprintf(os.Stderr, "printing to the output: %v", err)
			}
			fmt.Println()
		}
	}
}
