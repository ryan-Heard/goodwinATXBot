package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
)

// containsQuestion checks if a message contains a question
func containsQuestion(text string) bool {
	if text == "" {
		return false
	}

	// Convert to lowercase for case-insensitive matching
	lowerText := toLower(text)

	// Check for question mark
	if contains(lowerText, "?") {
		return true
	}

	// Check for common question words
	questionWords := []string{
		"what is", "when", "where", "who",
		"why", "how", "is there",
		"can we",
	}
	for _, word := range questionWords {
		if contains(lowerText, word) {
			return true
		}
	}

	return false
}

// Helper function to convert string to lowercase
func toLower(s string) string {
	result := ""
	for _, r := range s {
		if r >= 'A' && r <= 'Z' {
			result += string(r + 32)
		} else {
			result += string(r)
		}
	}
	return result
}

// Helper function to check if string contains substring (case-insensitive)
func contains(s, substr string) bool {
	if substr == "" {
		return true
	}
	if len(s) < len(substr) {
		return false
	}

	s = toLower(s)
	substr = toLower(substr)

	for i := 0; i <= len(s)-len(substr); i++ {
		match := true
		for j := 0; j < len(substr); j++ {
			if s[i+j] != substr[j] {
				match = false
				break
			}
		}
		if match {
			return true
		}
	}
	return false
}

// generateQuestionResponse generates an appropriate response for a question
func generateQuestionResponse(question string) string {
	if question == "" {
		return ""
	}

	lowerQuestion := toLower(question)

	// Check for parking-related questions
	if contains(lowerQuestion, "parking") && contains(lowerQuestion, "code") {
		return "The guest parking code for Goodwin ATX is: GwPark01. Visit https://www.register2park.com/register to register your license plate for free parking."
	}

	// Check for weekly activities/events questions
	if contains(lowerQuestion, "week") || contains(lowerQuestion, "happening") {
		return generateWeeklySuggestion()
	}

	// Default response for other questions
	return ""
}

// sendGroupMeMessage sends a message to the GroupMe group
func sendGroupMeMessage(groupID, text string) error {
	botID := os.Getenv("GROUPME_BOT_ID")
	if botID == "" {
		return fmt.Errorf("GROUPME_BOT_ID not set")
	}

	// Check if we're in test mode (using dummy credentials)
	if botID == "test-bot-id" {
		log.Printf("🧪 TEST MODE: Would send message to GroupMe group %s: %s", groupID, text)
		return nil
	}

	// GroupMe bot post API endpoint
	apiURL := "https://api.groupme.com/v3/bots/post"

	// Prepare the message payload
	payload := map[string]string{
		"bot_id": botID,
		"text":   text,
	}

	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("error marshaling payload: %v", err)
	}

	// Create HTTP request
	req, err := http.NewRequest("POST", apiURL, bytes.NewBuffer(jsonPayload))
	if err != nil {
		return fmt.Errorf("error creating request: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")

	// Send the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("error sending request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusAccepted && resp.StatusCode != http.StatusOK {
		return fmt.Errorf("GroupMe API returned status: %d", resp.StatusCode)
	}

	log.Printf("Successfully sent message to GroupMe group %s: %s", groupID, text)
	return nil
}
