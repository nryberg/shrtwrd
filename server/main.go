package main

import (
	"bufio"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"os"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
)

var words []string
var syllableLookup map[string]int
var counterMutex sync.Mutex

const counterFile = "data/word_counter.txt"

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

func loadSyllables() {
	syllableLookup = make(map[string]int)

	// Try multiple possible locations for syllables.txt
	possiblePaths := []string{
		"utils/syllables.txt",
		"../utils/syllables.txt",
		"../../utils/syllables.txt",
		"syllables.txt",
	}
	var file *os.File
	var err error

	for _, path := range possiblePaths {
		file, err = os.Open(path)
		if err == nil {
			log.Printf("Loading syllables from: %s", path)
			break
		}
	}

	if err != nil {
		log.Printf("Warning: Could not load syllables.txt, using fallback method: %v", err)
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		parts := strings.Split(line, ":")
		if len(parts) == 2 {
			word := parts[0]
			if count, err := strconv.Atoi(parts[1]); err == nil {
				syllableLookup[word] = count
			}
		}
	}

	if err := scanner.Err(); err != nil {
		log.Printf("Warning: Error reading syllables.txt: %v", err)
	}

	log.Printf("Loaded %d syllable entries", len(syllableLookup))
}

func readCounter() int {
	// Ensure data directory exists
	os.MkdirAll("data", 0755)

	data, err := ioutil.ReadFile(counterFile)
	if err != nil {
		return 0 // File doesn't exist yet, start from 0
	}

	count, err := strconv.Atoi(strings.TrimSpace(string(data)))
	if err != nil {
		return 0
	}
	return count
}

func updateCounter(wordsServed int) {
	counterMutex.Lock()
	defer counterMutex.Unlock()

	currentCount := readCounter()
	newCount := currentCount + wordsServed

	err := ioutil.WriteFile(counterFile, []byte(fmt.Sprintf("%d\n", newCount)), 0644)
	if err != nil {
		log.Printf("Error updating counter: %v", err)
	}
}

type WordResponse struct {
	Lines [][]string `json:"lines"`
	Stats struct {
		NumLines     int `json:"num_lines"`
		WordsPerLine int `json:"words_per_line"`
		TotalWords   int `json:"total_words"`
	} `json:"stats"`
}

func generateWords(numLines, wordsPerLine int) [][]string {
	var result [][]string
	for i := 0; i < numLines; i++ {
		selectedWords := make(map[string]bool)
		for len(selectedWords) < wordsPerLine {
			word := words[rand.Intn(len(words))]
			if !selectedWords[word] {
				selectedWords[word] = true
			}
		}

		var lineWords []string
		for word := range selectedWords {
			lineWords = append(lineWords, word)
		}
		result = append(result, lineWords)
	}

	// Update word counter
	totalWordsServed := numLines * wordsPerLine
	updateCounter(totalWordsServed)

	return result
}

func formatPlainText(wordLines [][]string) string {
	var result strings.Builder
	for _, line := range wordLines {
		result.WriteString(strings.Join(line, "-"))
		result.WriteString("\n")
	}

	// Add two blank lines and about/stats links
	result.WriteString("\n\nAbout: https://shrtwrd.com/about | Stats: https://shrtwrd.com/stats\n")

	return result.String()
}

func formatJSON(wordLines [][]string, numLines, wordsPerLine int) ([]byte, error) {
	response := WordResponse{
		Lines: wordLines,
	}
	response.Stats.NumLines = numLines
	response.Stats.WordsPerLine = wordsPerLine
	response.Stats.TotalWords = numLines * wordsPerLine

	return json.MarshalIndent(response, "", "  ")
}

func formatCSV(wordLines [][]string) (string, error) {
	var result strings.Builder
	writer := csv.NewWriter(&result)

	// Write header
	if len(wordLines) > 0 && len(wordLines[0]) > 0 {
		header := make([]string, len(wordLines[0]))
		for i := range header {
			header[i] = fmt.Sprintf("word_%d", i+1)
		}
		writer.Write(header)
	}

	// Write data rows
	for _, line := range wordLines {
		writer.Write(line)
	}

	writer.Flush()
	if err := writer.Error(); err != nil {
		return "", err
	}

	return result.String(), nil
}

func countSyllables(word string) int {
	if word == "" {
		return 0
	}

	// First try the lookup table
	if count, exists := syllableLookup[word]; exists {
		return count
	}

	word = strings.ToLower(word)

	// Count vowel groups (consecutive vowels count as one syllable)
	vowelPattern := regexp.MustCompile(`[aeiouy]+`)
	vowelGroups := vowelPattern.FindAllString(word, -1)
	syllables := len(vowelGroups)

	// Handle silent 'e' at the end
	if strings.HasSuffix(word, "e") && syllables > 1 {
		syllables--
	}

	// Handle special cases where 'y' might not be a vowel
	if strings.HasSuffix(word, "ly") && syllables > 1 {
		syllables--
	}

	// Every word has at least 1 syllable
	if syllables < 1 {
		syllables = 1
	}

	return syllables
}

func generateHaikuLine(targetSyllables int, maxAttempts int) []string {
	var line []string
	currentSyllables := 0
	attempts := 0

	for currentSyllables < targetSyllables && attempts < maxAttempts {
		// Calculate remaining syllables needed
		remaining := targetSyllables - currentSyllables

		// Try to find a word that fits
		wordAttempts := 0
		maxWordAttempts := 100

		for wordAttempts < maxWordAttempts {
			word := words[rand.Intn(len(words))]
			wordSyllables := countSyllables(word)

			// Accept the word if it fits exactly or if it's the last word and fits
			if wordSyllables == remaining || (wordSyllables <= remaining && wordSyllables > 0) {
				line = append(line, word)
				currentSyllables += wordSyllables
				break
			}
			wordAttempts++
		}

		// If we can't find a fitting word, break to avoid infinite loop
		if wordAttempts >= maxWordAttempts {
			break
		}

		attempts++
	}

	return line
}

func generateHaiku() [][]string {
	maxAttempts := 1000

	// Generate each line with target syllable counts
	firstLine := generateHaikuLine(5, maxAttempts)
	secondLine := generateHaikuLine(7, maxAttempts)
	thirdLine := generateHaikuLine(5, maxAttempts)

	return [][]string{firstLine, secondLine, thirdLine}
}

func formatHaikuPlainText(haikuLines [][]string) string {
	var result strings.Builder
	for i, line := range haikuLines {
		result.WriteString(strings.Join(line, " "))
		if i < len(haikuLines)-1 {
			result.WriteString("\n")
		}
	}

	// Add two blank lines and about/stats links
	result.WriteString("\n\nAbout: https://shrtwrd.com/about | Stats: https://shrtwrd.com/stats")

	return result.String()
}

type HaikuResponse struct {
	Lines [][]string `json:"lines"`
	Stats struct {
		FirstLineSyllables  int    `json:"first_line_syllables"`
		SecondLineSyllables int    `json:"second_line_syllables"`
		ThirdLineSyllables  int    `json:"third_line_syllables"`
		Pattern             string `json:"pattern"`
	} `json:"stats"`
}

func formatHaikuJSON(haikuLines [][]string) ([]byte, error) {
	response := HaikuResponse{
		Lines: haikuLines,
	}

	// Calculate actual syllable counts
	if len(haikuLines) >= 3 {
		response.Stats.FirstLineSyllables = 0
		for _, word := range haikuLines[0] {
			response.Stats.FirstLineSyllables += countSyllables(word)
		}

		response.Stats.SecondLineSyllables = 0
		for _, word := range haikuLines[1] {
			response.Stats.SecondLineSyllables += countSyllables(word)
		}

		response.Stats.ThirdLineSyllables = 0
		for _, word := range haikuLines[2] {
			response.Stats.ThirdLineSyllables += countSyllables(word)
		}

		response.Stats.Pattern = fmt.Sprintf("%d-%d-%d",
			response.Stats.FirstLineSyllables,
			response.Stats.SecondLineSyllables,
			response.Stats.ThirdLineSyllables)
	}

	return json.MarshalIndent(response, "", "  ")
}

func formatHaikuCSV(haikuLines [][]string) (string, error) {
	var result strings.Builder
	writer := csv.NewWriter(&result)

	// Write header
	writer.Write([]string{"line_number", "words", "syllable_count"})

	// Write data rows
	for i, line := range haikuLines {
		syllableCount := 0
		for _, word := range line {
			syllableCount += countSyllables(word)
		}

		writer.Write([]string{
			fmt.Sprintf("%d", i+1),
			strings.Join(line, " "),
			fmt.Sprintf("%d", syllableCount),
		})
	}

	writer.Flush()
	if err := writer.Error(); err != nil {
		return "", err
	}

	return result.String(), nil
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

API Formats:
Add ?format= parameter to change output format:
- https://shrtwrd.com?format=json → JSON response with metadata
- https://shrtwrd.com?format=csv → CSV format with headers
- https://shrtwrd.com (default) → plain text, hyphen-separated

Examples:
- https://shrtwrd.com → "happy-cloud-tree"
- https://two.shrtwrd.com/3?format=json → JSON with 3 lines of 2 words
- https://five.shrtwrd.com/1?format=csv → CSV with 1 line of 5 words

You can generate between 1 and 100 lines per request. Words are randomly selected and output in your preferred format.

Haiku Generator:
- https://shrtwrd.com/haiku → Generate a random word haiku (5-7-5 syllable pattern)
- https://shrtwrd.com/haiku?format=json → JSON haiku with syllable analysis
- https://shrtwrd.com/haiku?format=csv → CSV format with syllable counts per line

The haiku generator creates three-line poems using random words arranged in the traditional 5-7-5 syllable pattern.

Statistics:
- https://shrtwrd.com/stats → view total words served
- https://shrtwrd.com/stats?format=json → JSON API with word count and timestamp
- https://shrtwrd.com/stats?format=csv → CSV download with current statistics
- https://shrtwrd.com/stats.csv → download historical stats CSV file

Perfect for generating unique names, creative inspiration, or random text for testing purposes.`

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	fmt.Fprint(w, aboutText)
}

type StatsResponse struct {
	TotalWordsServed int       `json:"total_words_served"`
	Timestamp        time.Time `json:"timestamp"`
}

func statsHandler(w http.ResponseWriter, r *http.Request) {
	counterMutex.Lock()
	currentCount := readCounter()
	counterMutex.Unlock()

	// Get format parameter
	format := r.URL.Query().Get("format")

	// Handle JSON/API format
	if format == "json" || format == "api" {
		response := StatsResponse{
			TotalWordsServed: currentCount,
			Timestamp:        time.Now(),
		}

		w.Header().Set("Content-Type", "application/json")
		jsonData, err := json.MarshalIndent(response, "", "  ")
		if err != nil {
			http.Error(w, "Error formatting JSON", http.StatusInternalServerError)
			return
		}
		w.Write(jsonData)
		return
	}

	// Handle CSV format
	if format == "csv" {
		timestamp := time.Now()
		w.Header().Set("Content-Type", "text/csv")
		w.Header().Set("Content-Disposition", "attachment; filename=\"stats.csv\"")

		// Write CSV header and data
		fmt.Fprintf(w, "total_words_served,timestamp\n")
		fmt.Fprintf(w, "%d,%s\n", currentCount, timestamp.Format(time.RFC3339))
		return
	}

	// Default plain text format
	statsText := fmt.Sprintf(`Random Word Generator - Statistics

Total words served: %d

This counter tracks every word generated across all requests.
Word count increases by:
- Subdomain multiplier (one=1, two=2, three=3, etc.)
- Number of lines requested (/5 = 5x multiplier)

Examples:
- https://shrtwrd.com (3 words) adds 3 to counter
- https://two.shrtwrd.com/5 (2 words × 5 lines = 10 words) adds 10 to counter
- https://six.shrtwrd.com/10 (6 words × 10 lines = 60 words) adds 60 to counter

API Formats:
- https://shrtwrd.com/stats?format=json → JSON response with timestamp
- https://shrtwrd.com/stats?format=csv → CSV file download

Back to generator: https://shrtwrd.com
About: https://shrtwrd.com/about`, currentCount)

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	fmt.Fprint(w, statsText)
}

func downloadStatsCSV(w http.ResponseWriter, r *http.Request) {
	// Try multiple possible locations for the stats CSV file
	possiblePaths := []string{
		"utils/stats.csv",
		"../utils/stats.csv",
		"../../utils/stats.csv",
		"stats.csv",
	}

	var csvData []byte
	var err error
	var foundPath string

	for _, path := range possiblePaths {
		log.Printf("Trying to read stats CSV from: %s", path)
		csvData, err = ioutil.ReadFile(path)
		if err == nil {
			foundPath = path
			log.Printf("Successfully found stats CSV at: %s", path)
			break
		} else {
			log.Printf("Failed to read %s: %v", path, err)
		}
	}

	if err != nil {
		// If no historical file exists, create a basic CSV with current stats
		counterMutex.Lock()
		currentCount := readCounter()
		counterMutex.Unlock()

		timestamp := time.Now()
		csvContent := fmt.Sprintf("timestamp,total_words_served,fetch_time\n%s,%d,%s\n",
			timestamp.Format(time.RFC3339), currentCount, timestamp.Format(time.RFC3339))

		w.Header().Set("Content-Type", "text/csv")
		w.Header().Set("Content-Disposition", "attachment; filename=\"stats.csv\"")
		fmt.Fprint(w, csvContent)
		return
	}

	// Serve the existing CSV file
	w.Header().Set("Content-Type", "text/csv")
	w.Header().Set("Content-Disposition", "attachment; filename=\"stats.csv\"")
	w.Write(csvData)

	log.Printf("Served stats CSV from: %s", foundPath)
}

func haikuHandler(w http.ResponseWriter, r *http.Request) {
	// Get format parameter
	format := r.URL.Query().Get("format")
	if format == "" {
		format = "text" // default
	}

	// Generate haiku
	haikuLines := generateHaiku()

	// Count total words generated and update counter
	totalWords := 0
	for _, line := range haikuLines {
		totalWords += len(line)
	}
	updateCounter(totalWords)

	// Format output based on requested format
	switch format {
	case "json":
		w.Header().Set("Content-Type", "application/json")
		jsonData, err := formatHaikuJSON(haikuLines)
		if err != nil {
			http.Error(w, "Error formatting JSON", http.StatusInternalServerError)
			return
		}
		w.Write(jsonData)

	case "csv":
		w.Header().Set("Content-Type", "text/csv")
		w.Header().Set("Content-Disposition", "attachment; filename=\"haiku.csv\"")
		csvData, err := formatHaikuCSV(haikuLines)
		if err != nil {
			http.Error(w, "Error formatting CSV", http.StatusInternalServerError)
			return
		}
		fmt.Fprint(w, csvData)

	default: // "text" or anything else defaults to plain text
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		fmt.Fprint(w, formatHaikuPlainText(haikuLines))
	}
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

	// Handle stats page
	if path == "stats" {
		statsHandler(w, r)
		return
	}

	// Handle stats CSV download
	if path == "stats.csv" || path == "download/stats.csv" {
		downloadStatsCSV(w, r)
		return
	}

	// Handle haiku generation
	if path == "haiku" {
		haikuHandler(w, r)
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

	// Get format parameter
	format := r.URL.Query().Get("format")
	if format == "" {
		format = "text" // default
	}

	// Generate words
	wordLines := generateWords(numLines, wordsPerLine)

	// Format output based on requested format
	switch format {
	case "json":
		w.Header().Set("Content-Type", "application/json")
		jsonData, err := formatJSON(wordLines, numLines, wordsPerLine)
		if err != nil {
			http.Error(w, "Error formatting JSON", http.StatusInternalServerError)
			return
		}
		w.Write(jsonData)

	case "csv":
		w.Header().Set("Content-Type", "text/csv")
		w.Header().Set("Content-Disposition", "attachment; filename=\"words.csv\"")
		csvData, err := formatCSV(wordLines)
		if err != nil {
			http.Error(w, "Error formatting CSV", http.StatusInternalServerError)
			return
		}
		fmt.Fprint(w, csvData)

	default: // "text" or anything else defaults to plain text
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		fmt.Fprint(w, formatPlainText(wordLines))
	}
}

func main() {
	rand.Seed(time.Now().UnixNano())
	loadWords()
	loadSyllables()

	port := os.Getenv("PORT")
	if port == "" {
		port = "80"
	}

	http.HandleFunc("/", handler)
	log.Printf("Starting server on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
