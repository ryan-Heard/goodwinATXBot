package main

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestContainsQuestion(t *testing.T) {
	tests := []struct {
		name     string
		text     string
		expected bool
	}{
		{"Question mark at end", "What time is it?", true},
		{"Contains 'what'", "what is happening", true},
		{"Contains 'when'", "when do we meet", true},
		{"Contains 'where'", "where is the location", true},
		{"Contains 'who'", "who is coming", true},
		{"Contains 'why'", "why did this happen", true},
		{"Contains 'how'", "how do I register", true},
		{"Regular statement", "This is a statement", false},
		{"Empty string", "", false},
		{"Mixed case what", "WHAT is the answer", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := containsQuestion(tt.text)
			if result != tt.expected {
				t.Errorf("containsQuestion(%q) = %v; expected %v", tt.text, result, tt.expected)
			}
		})
	}
}

func TestGenerateQuestionResponse(t *testing.T) {
	tests := []struct {
		name     string
		question string
		expected string
	}{
		{
			"Guest parking code question",
			"Where can I find guest parking code?",
			"The guest parking code for Goodwin ATX is: GwPark01. Visit https://www.register2park.com/register to register your license plate for free parking.",
		},
		{
			"Guest parking code mixed case",
			"guest parking CODE information",
			"The guest parking code for Goodwin ATX is: GwPark01. Visit https://www.register2park.com/register to register your license plate for free parking.",
		},
		{"Non-parking related question", "What time is the meeting?", ""},
		{"Empty question", "", ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := generateQuestionResponse(tt.question)
			if result != tt.expected {
				t.Errorf("generateQuestionResponse(%q) = %q; expected %q", tt.question, result, tt.expected)
			}
		})
	}
}

func TestGenerateWeeklySuggestion(t *testing.T) {
	suggestion := generateWeeklySuggestion()
	if suggestion == "" {
		t.Error("generateWeeklySuggestion() returned empty string")
	}

	expectedSuggestions := []string{
		"🎉 Weekly Suggestion: Check out the new events happening at Goodwin this week!",
		"🌟 Weekly Tip: Don't forget to RSVP for upcoming events!",
		"📅 Weekly Reminder: Great things happening this week - stay connected!",
		"💡 Weekly Suggestion: Explore new opportunities at Goodwin this week!",
	}

	found := false
	for _, expected := range expectedSuggestions {
		if suggestion == expected {
			found = true
			break
		}
	}

	if !found {
		t.Errorf("generateWeeklySuggestion() returned unexpected suggestion: %q", suggestion)
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
		{"Already lowercase", "hello", "hello"},
		{"Numbers and symbols", "Hello123!@#", "hello123!@#"},
		{"Empty string", "", ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := toLower(tt.input)
			if result != tt.expected {
				t.Errorf("toLower(%q) = %q; expected %q", tt.input, result, tt.expected)
			}
		})
	}
}

func TestContains(t *testing.T) {
	tests := []struct {
		name     string
		str      string
		substr   string
		expected bool
	}{
		{"Contains substring", "Hello World", "World", true},
		{"Case insensitive match", "Hello World", "world", true},
		{"Does not contain", "Hello World", "Goodbye", false},
		{"Empty substring", "Hello World", "", true},
		{"Empty string", "", "test", false},
		{"Both empty", "", "", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := contains(tt.str, tt.substr)
			if result != tt.expected {
				t.Errorf("contains(%q, %q) = %v; expected %v", tt.str, tt.substr, result, tt.expected)
			}
		})
	}
}

func TestJSONParsing(t *testing.T) {
	validJSON := `{"sender_type": "user", "text": "Hello", "group_id": "test"}`
	var callback GroupMeCallback
	err := json.Unmarshal([]byte(validJSON), &callback)
	if err != nil {
		t.Errorf("Should parse valid JSON: %v", err)
	}

	invalidJSON := `{"invalid": json}`
	err = json.Unmarshal([]byte(invalidJSON), &callback)
	if err == nil {
		t.Error("Should fail on invalid JSON")
	}
}

func TestEdgeCases(t *testing.T) {
	t.Run("Very long message", func(t *testing.T) {
		longText := strings.Repeat("What ", 100) + "is this?"
		result := containsQuestion(longText)
		if !result {
			t.Error("Should detect question in very long text")
		}
	})

	t.Run("Unicode question mark", func(t *testing.T) {
		unicodeText := "¿Qué está pasando?"
		result := containsQuestion(unicodeText)
		if !result {
			t.Error("Should handle unicode question marks")
		}
	})
}

func BenchmarkContainsQuestion(b *testing.B) {
	testText := "What is the meaning of life?"
	for i := 0; i < b.N; i++ {
		containsQuestion(testText)
	}
}

func BenchmarkGenerateQuestionResponse(b *testing.B) {
	testQuestion := "Where can I find guest parking code?"
	for i := 0; i < b.N; i++ {
		generateQuestionResponse(testQuestion)
	}
}
