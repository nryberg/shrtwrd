package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHandler(t *testing.T) {
	loadWords()

	t.Run("default three words per line", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/", nil)
		if err != nil {
			t.Fatal(err)
		}

		rr := httptest.NewRecorder()
		handler(rr, req)

		if status := rr.Code; status != http.StatusOK {
			t.Errorf("handler returned wrong status code: got %v want %v",
				status, http.StatusOK)
		}

		lines := strings.Split(strings.TrimSpace(rr.Body.String()), "\n")
		if len(lines) != 1 {
			t.Errorf("handler returned wrong number of lines: got %v want %v", len(lines), 1)
		}
		words := strings.Split(lines[0], "-")
		if len(words) != 3 {
			t.Errorf("handler returned wrong number of words: got %v want %v", len(words), 3)
		}
	})

	t.Run("one word per line (subdomain)", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/", nil)
		if err != nil {
			t.Fatal(err)
		}
		req.Host = "one.example.com"

		rr := httptest.NewRecorder()
		handler(rr, req)

		if status := rr.Code; status != http.StatusOK {
			t.Errorf("handler returned wrong status code: got %v want %v",
				status, http.StatusOK)
		}

		lines := strings.Split(strings.TrimSpace(rr.Body.String()), "\n")
		if len(lines) != 1 {
			t.Errorf("handler returned wrong number of lines: got %v want %v", len(lines), 1)
		}
		words := strings.Split(lines[0], "-")
		if len(words) != 1 {
			t.Errorf("handler returned wrong number of words: got %v want %v", len(words), 1)
		}
	})

	t.Run("two words per line (subdomain)", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/", nil)
		if err != nil {
			t.Fatal(err)
		}
		req.Host = "two.example.com"

		rr := httptest.NewRecorder()
		handler(rr, req)

		if status := rr.Code; status != http.StatusOK {
			t.Errorf("handler returned wrong status code: got %v want %v",
				status, http.StatusOK)
		}

		lines := strings.Split(strings.TrimSpace(rr.Body.String()), "\n")
		if len(lines) != 1 {
			t.Errorf("handler returned wrong number of lines: got %v want %v", len(lines), 1)
		}
		words := strings.Split(lines[0], "-")
		if len(words) != 2 {
			t.Errorf("handler returned wrong number of words: got %v want %v", len(words), 2)
		}
	})

	t.Run("four words per line (subdomain)", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/", nil)
		if err != nil {
			t.Fatal(err)
		}
		req.Host = "four.example.com"

		rr := httptest.NewRecorder()
		handler(rr, req)

		if status := rr.Code; status != http.StatusOK {
			t.Errorf("handler returned wrong status code: got %v want %v",
				status, http.StatusOK)
		}

		lines := strings.Split(strings.TrimSpace(rr.Body.String()), "\n")
		if len(lines) != 1 {
			t.Errorf("handler returned wrong number of lines: got %v want %v", len(lines), 1)
		}
		words := strings.Split(lines[0], "-")
		if len(words) != 4 {
			t.Errorf("handler returned wrong number of words: got %v want %v", len(words), 4)
		}
	})

	t.Run("five words per line (subdomain)", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/", nil)
		if err != nil {
			t.Fatal(err)
		}
		req.Host = "five.example.com"

		rr := httptest.NewRecorder()
		handler(rr, req)

		if status := rr.Code; status != http.StatusOK {
			t.Errorf("handler returned wrong status code: got %v want %v",
				status, http.StatusOK)
		}

		lines := strings.Split(strings.TrimSpace(rr.Body.String()), "\n")
		if len(lines) != 1 {
			t.Errorf("handler returned wrong number of lines: got %v want %v", len(lines), 1)
		}
		words := strings.Split(lines[0], "-")
		if len(words) != 5 {
			t.Errorf("handler returned wrong number of words: got %v want %v", len(words), 5)
		}
	})

	t.Run("specific number of lines with subdomain", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/5", nil)
		if err != nil {
			t.Fatal(err)
		}
		req.Host = "one.example.com"

		rr := httptest.NewRecorder()
		handler(rr, req)

		if status := rr.Code; status != http.StatusOK {
			t.Errorf("handler returned wrong status code: got %v want %v",
				status, http.StatusOK)
		}

		lines := strings.Split(strings.TrimSpace(rr.Body.String()), "\n")
		if len(lines) != 5 {
			t.Errorf("handler returned wrong number of lines: got %v want %v", len(lines), 5)
		}
		words := strings.Split(lines[0], "-")
		if len(words) != 1 {
			t.Errorf("handler returned wrong number of words: got %v want %v", len(words), 1)
		}
	})

	t.Run("invalid number of lines (too many)", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/101", nil)
		if err != nil {
			t.Fatal(err)
		}

		rr := httptest.NewRecorder()
		handler(rr, req)

		if status := rr.Code; status != http.StatusBadRequest {
			t.Errorf("handler returned wrong status code: got %v want %v",
				status, http.StatusBadRequest)
		}
	})

	t.Run("invalid path", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/foo", nil)
		if err != nil {
			t.Fatal(err)
		}

		rr := httptest.NewRecorder()
		handler(rr, req)

		if status := rr.Code; status != http.StatusBadRequest {
			t.Errorf("handler returned wrong status code: got %v want %v",
				status, http.StatusBadRequest)
		}
	})

	t.Run("stats endpoint plain text", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/stats", nil)
		if err != nil {
			t.Fatal(err)
		}

		rr := httptest.NewRecorder()
		handler(rr, req)

		if status := rr.Code; status != http.StatusOK {
			t.Errorf("handler returned wrong status code: got %v want %v",
				status, http.StatusOK)
		}

		if !strings.Contains(rr.Body.String(), "Total words served:") {
			t.Errorf("stats response should contain 'Total words served:'")
		}

		contentType := rr.Header().Get("Content-Type")
		if contentType != "text/plain; charset=utf-8" {
			t.Errorf("handler returned wrong content type: got %v want %v",
				contentType, "text/plain; charset=utf-8")
		}
	})

	t.Run("stats endpoint JSON format", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/stats?format=json", nil)
		if err != nil {
			t.Fatal(err)
		}

		rr := httptest.NewRecorder()
		handler(rr, req)

		if status := rr.Code; status != http.StatusOK {
			t.Errorf("handler returned wrong status code: got %v want %v",
				status, http.StatusOK)
		}

		contentType := rr.Header().Get("Content-Type")
		if contentType != "application/json" {
			t.Errorf("handler returned wrong content type: got %v want %v",
				contentType, "application/json")
		}

		if !strings.Contains(rr.Body.String(), "total_words_served") {
			t.Errorf("JSON stats response should contain 'total_words_served'")
		}

		if !strings.Contains(rr.Body.String(), "timestamp") {
			t.Errorf("JSON stats response should contain 'timestamp'")
		}
	})

	t.Run("stats endpoint API format", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/stats?format=api", nil)
		if err != nil {
			t.Fatal(err)
		}

		rr := httptest.NewRecorder()
		handler(rr, req)

		if status := rr.Code; status != http.StatusOK {
			t.Errorf("handler returned wrong status code: got %v want %v",
				status, http.StatusOK)
		}

		contentType := rr.Header().Get("Content-Type")
		if contentType != "application/json" {
			t.Errorf("handler returned wrong content type: got %v want %v",
				contentType, "application/json")
		}

		if !strings.Contains(rr.Body.String(), "total_words_served") {
			t.Errorf("API stats response should contain 'total_words_served'")
		}

		if !strings.Contains(rr.Body.String(), "timestamp") {
			t.Errorf("API stats response should contain 'timestamp'")
		}
	})

	t.Run("stats endpoint CSV format", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/stats?format=csv", nil)
		if err != nil {
			t.Fatal(err)
		}

		rr := httptest.NewRecorder()
		handler(rr, req)

		if status := rr.Code; status != http.StatusOK {
			t.Errorf("handler returned wrong status code: got %v want %v",
				status, http.StatusOK)
		}

		contentType := rr.Header().Get("Content-Type")
		if contentType != "text/csv" {
			t.Errorf("handler returned wrong content type: got %v want %v",
				contentType, "text/csv")
		}

		contentDisposition := rr.Header().Get("Content-Disposition")
		expectedDisposition := "attachment; filename=\"stats.csv\""
		if contentDisposition != expectedDisposition {
			t.Errorf("handler returned wrong content disposition: got %v want %v",
				contentDisposition, expectedDisposition)
		}

		body := rr.Body.String()
		if !strings.Contains(body, "total_words_served,timestamp") {
			t.Errorf("CSV stats response should contain header 'total_words_served,timestamp'")
		}

		lines := strings.Split(strings.TrimSpace(body), "\n")
		if len(lines) != 2 {
			t.Errorf("CSV should have 2 lines (header + data), got %d", len(lines))
		}

		// Check data line has correct format (number,timestamp)
		if len(lines) > 1 {
			parts := strings.Split(lines[1], ",")
			if len(parts) != 2 {
				t.Errorf("CSV data line should have 2 columns, got %d", len(parts))
			}
		}
	})
}
