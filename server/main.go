package main

import (
	"bufio"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

var words []string

func loadWords() {
	// Try multiple possible locations for words.txt
	possiblePaths := []string{"words.txt", "../words.txt", "../../words.txt"}
	var file *os.File
	var err error

	for _, path := range possiblePaths {
		file, err = os.Open(path)
		if err == nil {
			break
		}
	}

	if err != nil {
		log.Fatalf("Error opening words.txt: %v", err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		words = append(words, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		log.Fatalf("Error reading words.txt: %v", err)
	}
}

func generateWords(numLines, wordsPerLine int) string {
	var result strings.Builder
	for i := 0; i < numLines; i++ {
		selectedWords := make(map[string]bool)
		for len(selectedWords) < wordsPerLine {
			word := words[rand.Intn(len(words))]
			if !selectedWords[word] {
				selectedWords[word] = true
			}
		}

		first := true
		for word := range selectedWords {
			if !first {
				result.WriteString("-")
			}
			result.WriteString(word)
			first = false
		}
		result.WriteString("\n")
	}

	// Add two blank lines and about link
	result.WriteString("\n\nAbout: https://shrtwrd.com/about\n")

	return result.String()
}

func aboutHandler(w http.ResponseWriter, r *http.Request) {
	aboutText := `Random Word Generator

This service generates random words for various purposes including naming projects, creating passwords, brainstorming, or just for fun.

How to Use:

Basic Usage:
Visit any domain to get 3 random words (default):
- https://shrtwrd.com → generates 3 words

Specify Word Count by Subdomain:
- https://one.shrtwrd.com → 1 word per line
- https://two.shrtwrd.com → 2 words per line
- https://three.shrtwrd.com → 3 words per line
- https://four.shrtwrd.com → 4 words per line
- https://five.shrtwrd.com → 5 words per line
- https://six.shrtwrd.com → 6 words per line

Specify Number of Lines:
Add a number to the URL path to generate multiple lines:
- https://shrtwrd.com/5 → 5 lines of 3 words each
- https://two.shrtwrd.com/10 → 10 lines of 2 words each
- https://one.shrtwrd.com/20 → 20 lines of 1 word each

Examples:
- https://shrtwrd.com → "happy-cloud-tree"
- https://two.shrtwrd.com/3 → generates 3 lines, each with 2 words
- https://five.shrtwrd.com/1 → generates 1 line with 5 words

You can generate between 1 and 100 lines per request. Words are randomly selected and hyphen-separated on each line.

Perfect for generating unique names, creative inspiration, or random text for testing purposes.`

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	fmt.Fprint(w, aboutText)
}

func handler(w http.ResponseWriter, r *http.Request) {
	numLines := 1
	wordsPerLine := 3 // Default

	hostParts := strings.Split(r.Host, ".")
	if len(hostParts) > 1 {
		switch hostParts[0] {
		case "one":
			wordsPerLine = 1
		case "two":
			wordsPerLine = 2
		case "three":
			wordsPerLine = 3
		case "four":
			wordsPerLine = 4
		case "five":
			wordsPerLine = 5
		case "six":
			wordsPerLine = 6
		}
	}

	path := strings.TrimPrefix(r.URL.Path, "/")

	// Handle about page
	if path == "about" {
		aboutHandler(w, r)
		return
	}

	if path != "" {
		if n, err := strconv.Atoi(path); err == nil {
			if n > 0 && n <= 100 {
				numLines = n
			} else {
				http.Error(w, "Number of lines must be between 1 and 100", http.StatusBadRequest)
				return
			}
		} else {
			http.Error(w, "Invalid path. Use / or /{number}", http.StatusBadRequest)
			return
		}
	}

	fmt.Fprintf(w, generateWords(numLines, wordsPerLine))
}

func main() {
	rand.Seed(time.Now().UnixNano())
	loadWords()

	port := os.Getenv("PORT")
	if port == "" {
		port = "80"
	}

	http.HandleFunc("/", handler)
	log.Printf("Starting server on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
