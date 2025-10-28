package main

import (
	"bytes"
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Health check endpoint
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("Health check request from %s", r.RemoteAddr)
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Main GroupMe webhook endpoint
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("Received %s request from %s", r.Method, r.RemoteAddr)

		if r.Method != "POST" {
			log.Printf("Invalid method: %s", r.Method)
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var buf bytes.Buffer
		_, err := buf.ReadFrom(r.Body)
		if err != nil {
			log.Printf("Error reading request body: %v", err)
			http.Error(w, "Error reading request body", http.StatusBadRequest)
			return
		}

		body := buf.String()
		log.Printf("Request body: %s", body)

		err = handleGroupMeCallback(context.Background(), body)
		if err != nil {
			log.Printf("Error handling callback: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Scheduled endpoint for weekly suggestions
	http.HandleFunc("/scheduled", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("Received scheduled request from %s", r.RemoteAddr)

		err := handleScheduledSuggestions(context.Background())
		if err != nil {
			log.Printf("Error handling scheduled suggestion: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Weekly suggestion sent"))
	})

	log.Printf("Starting server on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

// handleGroupMeCallback processes incoming GroupMe messages
func handleGroupMeCallback(ctx context.Context, body string) error {
	var callback GroupMeCallback

	err := json.Unmarshal([]byte(body), &callback)
	if err != nil {
		log.Printf("Error parsing callback: %v", err)
		return err
	}

	// Ignore bot's own messages
	if callback.SenderType == "bot" {
		log.Printf("Ignoring bot message")
		return nil
	}

	log.Printf("Processing message from %s: %s", callback.Name, callback.Text)

	// Check if the message is a question (contains '?')
	if containsQuestion(callback.Text) {
		response := generateQuestionResponse(callback.Text)
		err = sendGroupMeMessage(callback.GroupID, response)
		if err != nil {
			log.Printf("Error sending message: %v", err)
			return err
		}
	}

	return nil
}
