# Customization Examples

This document provides examples for customizing the Goodwin ATX Bot to better suit your community's needs.

## Custom Question Responses

### Example 1: Context-Aware Responses

Modify the `generateQuestionResponse()` function in `main.go`:

```go
func generateQuestionResponse(question string) string {
    questionLower := toLower(question)
    
    // Location-related questions
    if contains(questionLower, "where") {
        if contains(questionLower, "event") || contains(questionLower, "meeting") {
            return "Most events are at Goodwin ATX! Check the latest announcement for the specific location."
        }
        return "Great question about location! Check the group chat for address details."
    }
    
    // Time-related questions
    if contains(questionLower, "when") || contains(questionLower, "time") {
        return "⏰ Check the pinned messages or latest announcement for event times!"
    }
    
    // People-related questions
    if contains(questionLower, "who") {
        if contains(questionLower, "organizing") || contains(questionLower, "host") {
            return "Our events are organized by the Goodwin community! Check with @organizers for details."
        }
        return "Good question! Tag the organizers or check recent messages for attendee info."
    }
    
    // Default responses
    responses := []string{
        "That's a great question! Let me think about that...",
        "Interesting question! Check the pinned messages or ask the group!",
        "Good question! Someone in the group should know - stay tuned!",
    }
    
    hash := 0
    for _, c := range question {
        hash += int(c)
    }
    
    return responses[hash%len(responses)]
}
```

### Example 2: Keyword-Based Auto Responses

```go
func generateQuestionResponse(question string) string {
    questionLower := toLower(question)
    
    // FAQ responses
    faqs := map[string]string{
        "parking":  "🚗 Parking is available on the street and in nearby lots. Arrive early for best spots!",
        "food":     "🍕 Food and drinks will be provided! Let us know about dietary restrictions.",
        "cost":     "💰 Most events are free for members! Check the specific event announcement.",
        "rsvp":     "📝 RSVP by reacting to the event message or messaging the organizers!",
        "bring":    "🎒 Just bring yourself and a positive attitude! Anything else will be mentioned in the event details.",
        "newcomer": "👋 Newcomers are always welcome! Introduce yourself in the chat, we're friendly!",
    }
    
    // Check for keywords
    for keyword, response := range faqs {
        if contains(questionLower, keyword) {
            return response
        }
    }
    
    return "Great question! Check the group chat or pinned messages for more info."
}
```

## Custom Weekly Suggestions

### Example 1: Day-Specific Messages

```go
func generateWeeklySuggestion() string {
    // You could use time.Now() to get the current day
    // For now, we'll provide varied suggestions
    
    suggestions := []string{
        "🎉 Happy Monday! Check out this week's events at Goodwin ATX. Don't forget to RSVP!",
        "🌟 Weekly Spotlight: Connect with fellow members this week. New to the group? Introduce yourself!",
        "📅 This Week at Goodwin: Game night Thursday, Happy hour Friday! Mark your calendars!",
        "💡 Community Tip: Check the pinned messages for important updates and upcoming events!",
        "🚀 Start your week right! Join us for this week's activities and meet amazing people!",
    }
    
    // Simple rotation (in production, could use time-based selection)
    return suggestions[0]
}
```

### Example 2: Time-Based Rotation

Add this import at the top of `main.go`:
```go
import (
    "time"
    // ... other imports
)
```

Then modify the function:
```go
func generateWeeklySuggestion() string {
    suggestions := []string{
        "🎉 Happy Monday! New week, new opportunities at Goodwin ATX!",
        "🌟 Tuesday Vibes: Stay connected and check this week's events!",
        "📅 Midweek Update: Don't miss out on upcoming Goodwin activities!",
        "💡 Thursday Thoughts: Weekend events coming up - get ready!",
        "🚀 Friday Energy: Weekend plans at Goodwin? Check the schedule!",
    }
    
    // Get current weekday (0 = Sunday, 1 = Monday, etc.)
    weekday := int(time.Now().Weekday())
    
    // Monday = 1, use modulo to cycle through suggestions
    index := (weekday - 1 + 7) % 7
    if index >= len(suggestions) {
        index = 0
    }
    
    return suggestions[index]
}
```

### Example 3: Event Reminders

```go
func generateWeeklySuggestion() string {
    // Get current week of the month
    now := time.Now()
    day := now.Day()
    weekOfMonth := (day-1)/7 + 1
    
    switch weekOfMonth {
    case 1:
        return "🎉 First week of the month! Monthly meetup this Friday at 7 PM!"
    case 2:
        return "📚 Second week: Book club discussion Thursday evening!"
    case 3:
        return "🎮 Third week: Game night Saturday! Bring your favorite games!"
    case 4:
        return "🍕 Fourth week: Community potluck dinner Sunday at 6 PM!"
    default:
        return "📅 Check the calendar for special end-of-month events!"
    }
}
```

## Adding New Event Types

### Example: React to Specific Keywords

Modify `handleGroupMeCallback()` in `main.go`:

```go
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

    textLower := toLower(callback.Text)
    
    // React to thank you messages
    if contains(textLower, "thank") && contains(textLower, "bot") {
        err = sendGroupMeMessage(callback.GroupID, "You're welcome! Happy to help! 😊")
        if err != nil {
            log.Printf("Error sending message: %v", err)
        }
        return events.APIGatewayProxyResponse{StatusCode: 200, Body: "OK"}, nil
    }
    
    // React to introductions
    if contains(textLower, "new here") || contains(textLower, "first time") {
        err = sendGroupMeMessage(callback.GroupID, "👋 Welcome to Goodwin ATX! We're glad to have you!")
        if err != nil {
            log.Printf("Error sending message: %v", err)
        }
        return events.APIGatewayProxyResponse{StatusCode: 200, Body: "OK"}, nil
    }

    // Check if the message is a question
    if containsQuestion(callback.Text) {
        response := generateQuestionResponse(callback.Text)
        err = sendGroupMeMessage(callback.GroupID, response)
        if err != nil {
            log.Printf("Error sending message: %v", err)
            return events.APIGatewayProxyResponse{StatusCode: 500}, err
        }
    }

    return events.APIGatewayProxyResponse{StatusCode: 200, Body: "OK"}, nil
}
```

## Changing the Schedule

### Different Schedule Options

Edit `terraform/variables.tf`:

**Every Monday at 2 PM UTC (default):**
```hcl
default = "cron(0 14 ? * MON *)"
```

**Every Friday at 5 PM UTC:**
```hcl
default = "cron(0 17 ? * FRI *)"
```

**Every Day at 9 AM UTC:**
```hcl
default = "cron(0 9 ? * * *)"
```

**First Monday of each month at 10 AM UTC:**
```hcl
default = "cron(0 10 ? * MON#1 *)"
```

**Every 7 days (simple interval):**
```hcl
default = "rate(7 days)"
```

See [AWS Schedule Expressions](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html) for more options.

## Advanced: Adding External APIs

### Example: Weather Updates

Add weather API integration:

```go
func getWeatherInfo() (string, error) {
    // Call weather API (example)
    apiKey := os.Getenv("WEATHER_API_KEY")
    city := "Austin"
    
    url := fmt.Sprintf("https://api.openweathermap.org/data/2.5/weather?q=%s&appid=%s", city, apiKey)
    
    resp, err := http.Get(url)
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()
    
    // Parse response and format message
    // ... (implementation details)
    
    return "☀️ Weather in Austin: Sunny, 75°F", nil
}

func generateWeeklySuggestion() string {
    weather, err := getWeatherInfo()
    if err != nil {
        weather = "Check local weather before heading out!"
    }
    
    return fmt.Sprintf("🎉 Weekly Update: Great events this week at Goodwin! %s", weather)
}
```

Don't forget to add the API key to Terraform:

```hcl
# In terraform/lambda.tf
environment {
  variables = {
    GROUPME_BOT_ID    = var.groupme_bot_id
    GROUPME_GROUP_ID  = var.groupme_group_id
    WEATHER_API_KEY   = var.weather_api_key  # Add this
  }
}
```

## Testing Your Customizations

After making changes:

```bash
# Format code
make fmt

# Check for issues
make vet

# Run tests
make test

# Build
make build

# Deploy
make deploy
```

## Tips for Customization

1. **Start Small**: Make one change at a time and test it
2. **Test Locally**: Use Lambda test events before deploying
3. **Monitor Logs**: Watch CloudWatch Logs after deployment
4. **Backup**: Commit your changes to git before deploying
5. **Version Control**: Use git tags for major versions
6. **Community Feedback**: Ask your group what features they want

## Community-Specific Ideas

- **Event RSVP tracking**: Respond to reactions or keywords
- **Polls**: "Pizza or tacos?" - count responses
- **Reminders**: "Event starts in 1 hour!"
- **Fun facts**: Random trivia about Austin or your community
- **Member highlights**: Spotlight a member each week
- **Photo sharing**: Respond to photo uploads with comments
- **Link sharing**: Detect and categorize shared links

Remember to rebuild and redeploy after any changes:
```bash
make build && make deploy
```
