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
	version       = "development"
	currentSha    = "N/A"
)

var rootCmd = &cobra.Command{
	Use:   "figurine",
	Short: "Print any text in style",
	RunE: func(_ *cobra.Command, args []string) error {
		if list {
			listFonts()
			return nil
		}
		if len(args) > 0 && args[0] == "version" {
			fmt.Printf("figurine version %s (%s)\n", version, currentSha)
			return nil
		}
		return decorate(strings.Join(args, " "))
	},
}

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

	rootCmd.SetUsageTemplate(`Usage:{{if .Runnable}}
  {{.UseLine}}{{end}}{{if .HasAvailableSubCommands}}
  {{.CommandPath}} [command]{{end}}{{if gt (len .Aliases) 0}}

Aliases:
  {{.NameAndAliases}}{{end}}{{if .HasExample}}

Examples:
{{.Example}}{{end}}{{if .HasAvailableSubCommands}}

Available Commands:{{range .Commands}}{{if (or .IsAvailableCommand (eq .Name "help"))}}
  {{rpad .Name .NamePadding }} {{.Short}}{{end}}{{end}}{{end}}{{if .HasAvailableLocalFlags}}

Available Commands:
  help        Help about any command
  version     Print binary version information

Flags:
{{.LocalFlags.FlagUsages | trimTrailingWhitespaces}}{{end}}{{if .HasAvailableInheritedFlags}}

Global Flags:
{{.InheritedFlags.FlagUsages | trimTrailingWhitespaces}}{{end}}{{if .HasHelpSubCommands}}

Additional help topics:{{range .Commands}}{{if .IsAdditionalHelpTopicCommand}}
  {{rpad .CommandPath .CommandPathPadding}} {{.Short}}{{end}}{{end}}{{end}}{{if .HasAvailableSubCommands}}

Use "{{.CommandPath}} [command] --help" for more information about a command.{{end}}
`)
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
