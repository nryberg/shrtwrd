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
}