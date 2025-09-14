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
	return result.String()
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
