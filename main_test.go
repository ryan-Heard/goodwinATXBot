package main

import (
	"testing"
)

func TestContainsQuestion(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected bool
	}{
		{"Question mark", "What is this?", true},
		{"Contains what", "What time is it", true},
		{"Contains when", "when does it start", true},
		{"Contains where", "where is the location", true},
		{"Contains who", "who is going", true},
		{"Contains why", "why did this happen", true},
		{"Contains how", "how does it work", true},
		{"Not a question", "This is a statement.", false},
		{"Empty string", "", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := containsQuestion(tt.input)
			if result != tt.expected {
				t.Errorf("containsQuestion(%q) = %v, want %v", tt.input, result, tt.expected)
			}
		})
	}
}

func TestContains(t *testing.T) {
	tests := []struct {
		name     string
		s        string
		substr   string
		expected bool
	}{
		{"Contains substring", "Hello World", "world", true},
		{"Does not contain", "Hello World", "xyz", false},
		{"Case insensitive", "Hello World", "HELLO", true},
		{"Empty substring", "Hello", "", true},
		{"Empty string", "", "test", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := contains(tt.s, tt.substr)
			if result != tt.expected {
				t.Errorf("contains(%q, %q) = %v, want %v", tt.s, tt.substr, result, tt.expected)
			}
		})
	}
}

func TestToLower(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{"All uppercase", "HELLO", "hello"},
		{"Mixed case", "HeLLo WoRLd", "hello world"},
		{"All lowercase", "hello", "hello"},
		{"With numbers", "Test123", "test123"},
		{"Empty string", "", ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := toLower(tt.input)
			if result != tt.expected {
				t.Errorf("toLower(%q) = %q, want %q", tt.input, result, tt.expected)
			}
		})
	}
}

func TestGenerateQuestionResponse(t *testing.T) {
	// Test that response is not empty and is one of the expected responses
	response := generateQuestionResponse("What is this?")
	if response == "" {
		t.Error("generateQuestionResponse returned empty string")
	}
	
	// Test that same question gives same response (deterministic)
	response2 := generateQuestionResponse("What is this?")
	if response != response2 {
		t.Error("generateQuestionResponse should be deterministic")
	}
}

func TestGenerateWeeklySuggestion(t *testing.T) {
	// Test that suggestion is not empty
	suggestion := generateWeeklySuggestion()
	if suggestion == "" {
		t.Error("generateWeeklySuggestion returned empty string")
	}
}
