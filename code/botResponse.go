package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
)

// contains checks if a string contains a substring (case-insensitive)
func contains(s, substr string) bool {
	sLower := toLower(s)
	substrLower := toLower(substr)
	for i := 0; i <= len(sLower)-len(substrLower); i++ {
		if sLower[i:i+len(substrLower)] == substrLower {
			return true
		}
	}
	return false
}

// toLower converts a string to lowercase
func toLower(s string) string {
	result := make([]byte, len(s))
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c >= 'A' && c <= 'Z' {
			result[i] = c + 32
		} else {
			result[i] = c
		}
	}
	return string(result)
}

// containsQuestion checks if the text contains question indicators
func containsQuestion(text string) bool {
	return len(text) > 0 && (text[len(text)-1] == '?' ||
		contains(text, "what") ||
		contains(text, "when") ||
		contains(text, "where") ||
		contains(text, "who") ||
		contains(text, "why") ||
		contains(text, "how"))
}

// Group Routing Response logic here
func questionResponse(message GroupMeMessage) string {
	// Simple keyword-based response logic
	if message.Text == "Hello" || message.Text == "Hi" {
		return fmt.Sprintf("Hello, %s! How can I assist you today?", message.Name)
	} else if message.Text == "Help" {
		return "Sure! You can ask me about our services, opening hours, or any other questions you have."
	} else if bytes.Contains([]byte(message.Text), []byte("guest parking code")) {
		return "Guest parking vehicles can be https://www.register2park.com/register. " +
			"Use code GOODWIN123 for free parking. GwPark01"
	}

	return ""
}

// generateQuestionResponse generates a helpful response to a question
func generateQuestionResponse(question string) string {
	// Simple response logic - can be enhanced with more sophisticated AI/rules
	responses := []string{
		"That's a great question! Let me think about that...",
		"Interesting question! Here's what I know...",
		"Good question! Based on what I know...",
		"Let me help you with that!",
	}

	// Use a simple hash to pick a response
	hash := 0
	for _, c := range question {
		hash += int(c)
	}

	return responses[hash%len(responses)]
}

// sendGroupMeMessage sends a message to the GroupMe group
func sendGroupMeMessage(groupID, text string) error {
	botID := os.Getenv("GROUPME_BOT_ID")
	if botID == "" {
		return fmt.Errorf("GROUPME_BOT_ID not set")
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
