
package main

import (
	"bufio"
	"flag"
	"fmt"
	"math/rand"
	"os"
	"time"
)

func main() {
	linesPtr := flag.Int("lines", 1, "number of lines of random words to generate")
	lPtr := flag.Int("l", 1, "number of lines of random words to generate (shorthand)")
	flag.Parse()

	linesToGenerate := *linesPtr
	if *lPtr != 1 { // If -l is explicitly set, it overrides -lines
		linesToGenerate = *lPtr
	}

	if linesToGenerate > 100 {
		fmt.Println("Error: lines parameter cannot be greater than 100")
		os.Exit(1)
	}

	if linesToGenerate <= 0 {
		return
	}

	file, err := os.Open("words.txt")
	if err != nil {
		fmt.Println("Error opening file:", err)
		return
	}
	defer file.Close()

	var words []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		words = append(words, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		fmt.Println("Error reading file:", err)
		return
	}

	rand.Seed(time.Now().UnixNano())

	for i := 0; i < linesToGenerate; i++ {
		selectedWords := make(map[string]bool)
		for len(selectedWords) < 3 {
			word := words[rand.Intn(len(words))]
			if !selectedWords[word] {
				selectedWords[word] = true
			}
		}

		first := true
		for word := range selectedWords {
			if !first {
				fmt.Print("-")
			}
			fmt.Print(word)
			first = false
		}
		fmt.Println()
	}
}
