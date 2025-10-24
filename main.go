package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

// GroupMeMessage represents an incoming message from GroupMe
type GroupMeMessage struct {
	Name       string `json:"name"`
	Text       string `json:"text"`
	UserID     string `json:"user_id"`
	GroupID    string `json:"group_id"`
	AvatarURL  string `json:"avatar_url"`
	ID         string `json:"id"`
	SenderType string `json:"sender_type"`
	SourceGUID string `json:"source_guid"`
	System     bool   `json:"system"`
}

// GroupMeCallback represents the callback from GroupMe
type GroupMeCallback struct {
	Attachments []interface{} `json:"attachments"`
	AvatarURL   string        `json:"avatar_url"`
	CreatedAt   int64         `json:"created_at"`
	GroupID     string        `json:"group_id"`
	ID          string        `json:"id"`
	Name        string        `json:"name"`
	SenderID    string        `json:"sender_id"`
	SenderType  string        `json:"sender_type"`
	SourceGUID  string        `json:"source_guid"`
	System      bool          `json:"system"`
	Text        string        `json:"text"`
	UserID      string        `json:"user_id"`
}

// ScheduledEvent represents an EventBridge scheduled event
type ScheduledEvent struct {
	Source string                 `json:"source"`
	Detail map[string]interface{} `json:"detail"`
}

func main() {
	lambda.Start(HandleRequest)
}

// HandleRequest handles both webhook callbacks and scheduled events
func HandleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Printf("Received request: %+v", request)

	// Check if this is a scheduled event (weekly suggestions)
	if request.Headers["X-Amz-Event-Source"] == "aws:events" ||
		request.Path == "/scheduled" {
		return handleScheduledSuggestions(ctx, request)
	}

	// Otherwise, handle as GroupMe webhook callback
	return handleGroupMeCallback(ctx, request)
}

// handleGroupMeCallback processes incoming GroupMe messages
func handleGroupMeCallback(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var callback GroupMeCallback

	err := json.Unmarshal([]byte(request.Body), &callback)
	if err != nil {
		log.Printf("Error parsing callback: %v", err)
		return events.APIGatewayProxyResponse{StatusCode: 400}, err
	}

	// Ignore bot's own messages
	if callback.SenderType == "bot" {
		return events.APIGatewayProxyResponse{StatusCode: 200, Body: "OK"}, nil
	}

	// Check if the message is a question (contains '?')
	if containsQuestion(callback.Text) {
		response := generateQuestionResponse(callback.Text)
		err = sendGroupMeMessage(callback.GroupID, response)
		if err != nil {
			log.Printf("Error sending message: %v", err)
			return events.APIGatewayProxyResponse{StatusCode: 500}, err
		}
	}

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       "OK",
	}, nil
}

// handleScheduledSuggestions sends weekly suggestions
func handleScheduledSuggestions(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	groupID := os.Getenv("GROUPME_GROUP_ID")
	if groupID == "" {
		return events.APIGatewayProxyResponse{StatusCode: 500}, fmt.Errorf("GROUPME_GROUP_ID not set")
	}

	suggestion := generateWeeklySuggestion()
	err := sendGroupMeMessage(groupID, suggestion)
	if err != nil {
		log.Printf("Error sending weekly suggestion: %v", err)
		return events.APIGatewayProxyResponse{StatusCode: 500}, err
	}

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       "Weekly suggestion sent",
	}, nil
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

// generateWeeklySuggestion creates a weekly suggestion message
func generateWeeklySuggestion() string {
	suggestions := []string{
		"🎉 Weekly Suggestion: Check out the new events happening at Goodwin this week!",
		"🌟 Weekly Tip: Don't forget to RSVP for upcoming events!",
		"📅 Weekly Reminder: Great things happening this week - stay connected!",
		"💡 Weekly Suggestion: Explore new opportunities at Goodwin this week!",
	}

	// Rotate through suggestions based on current time
	// In production, you might use a more sophisticated selection
	return suggestions[0] // Can be enhanced with time-based rotation
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
