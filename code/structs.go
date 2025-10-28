package main

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
