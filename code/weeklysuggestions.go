package main

import (
	"context"
	"fmt"
	"log"
	"os"
)

// handleScheduledSuggestions sends weekly suggestions
func handleScheduledSuggestions(ctx context.Context) error {
	groupID := os.Getenv("GROUPME_GROUP_ID")
	if groupID == "" {
		return fmt.Errorf("GROUPME_GROUP_ID not set")
	}

	suggestion := generateWeeklySuggestion()
	err := sendGroupMeMessage(groupID, suggestion)
	if err != nil {
		log.Printf("Error sending weekly suggestion: %v", err)
		return err
	}

	log.Printf("Weekly suggestion sent successfully")
	return nil
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
