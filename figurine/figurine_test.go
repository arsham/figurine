// Copyright 2016 Arsham Shirvani <arshamshirvani@gmail.com>. All rights reserved.
// Use of this source code is governed by the Apache 2.0 license
// License that can be found in the LICENSE file.

package figurine_test

import (
	"fmt"
	"io"
	"testing"

	"github.com/arsham/figurine/figurine"
)

func BenchmarkGenerationPart(b *testing.B) {
	bcs := []string{
		"Arsham",
		"hRARbnf730ObNA1",
		"ZvooVEF2UOEg7k ha3IPoD319z9rWUEOUIH",
		"KjV8HeLaSV0MDiZFyXAg2XDCC MZv9O5d 1Z86mJ qw2d7Z0CAT7MrAunZH V74YD omlrSwpjXY2SxS6",
	}
	for _, bc := range bcs {
		bc := bc
		name := fmt.Sprintf("%d", len(bc))
		b.Run(name, func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				err := figurine.Write(io.Discard, bc, "Decimal.flf")
				if err != nil {
					b.Fatal(err)
				}
			}
		})
	}
}
