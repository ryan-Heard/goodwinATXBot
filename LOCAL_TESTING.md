# Local Testing Guide for Goodwin ATX Bot

## Quick Start

The Go program can be easily tested locally! Here are several ways to do it:

## Method 1: Automated Test Script (Recommended)

```bash
# Run the comprehensive test script
./test-local.sh
```

This script will:
- ✅ Build and start the server
- ✅ Test all endpoints automatically
- ✅ Show detailed logs
- ✅ Clean up when done

## Method 2: Manual Server Testing

### Start the Server

```bash
# Option A: Using Makefile
make run-local

# Option B: Direct Go command
PORT=8080 go run code/main.go

# Option C: With GroupMe credentials (for real testing)
GROUPME_BOT_ID=your-bot-id GROUPME_GROUP_ID=your-group-id PORT=8080 go run code/main.go
```

The server will start on `http://localhost:8080` and show available endpoints.

### Test the Endpoints

Open a new terminal and run these commands:

```bash
# 1. Health Check
curl http://localhost:8080/health

# 2. Test with a question (will trigger bot response)
curl -X POST http://localhost:8080/ \
  -H "Content-Type: application/json" \
  -d '{
    "text": "What events are happening this week?",
    "sender_type": "user",
    "group_id": "test-group-123",
    "name": "Test User"
  }'

# 3. Test weekly suggestions
curl -X POST http://localhost:8080/scheduled

# 4. Test with non-question (should be ignored)
curl -X POST http://localhost:8080/ \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello everyone!",
    "sender_type": "user",
    "group_id": "test-group-123",
    "name": "Test User"
  }'
```

### Using Makefile Test Commands

```bash
# Test individual endpoints (server must be running)
make test-health      # Test health endpoint
make test-webhook     # Test webhook with sample data
make test-schedule    # Test scheduled suggestions
```

## Method 3: Browser Testing

1. Start the server: `make run-local`
2. Open your browser to `http://localhost:8080/health`
3. You should see a JSON response with status information

## Environment Variables

### Required for GroupMe Integration
```bash
export GROUPME_BOT_ID="your-actual-bot-id"
export GROUPME_GROUP_ID="your-actual-group-id"
```

### Optional
```bash
export PORT=8080  # Default port (optional)
```

### Safe Testing (No GroupMe Messages)
For testing without sending real messages to GroupMe, use dummy values:
```bash
export GROUPME_BOT_ID="test-bot-id"
export GROUPME_GROUP_ID="test-group-id"
```

## What to Expect

### Successful Response Patterns

**Health Check:**
```json
{
  "status": "healthy",
  "service": "goodwin-atx-bot",
  "endpoints": "/health, /, /scheduled"
}
```

**Question Processing:**
- Server logs: "Received message from Test User: What events are happening?"
- Server logs: "Generated response: [response text]"
- If GroupMe credentials are real: Message sent to GroupMe
- If dummy credentials: Error logged (expected)

**Non-Question Messages:**
- Server logs: "Message doesn't contain a question, ignoring"

**Weekly Suggestions:**
- Server logs: "Generated weekly suggestion: [suggestion text]"
- Attempts to send to GroupMe (succeeds with real credentials)

## Troubleshooting

### Server Won't Start
- **Port in use**: Change PORT to different value (e.g., `PORT=8081`)
- **Build errors**: Run `go mod tidy` to fix dependencies

### API Calls Fail
- **Connection refused**: Make sure server is running on correct port
- **404 errors**: Check the endpoint URL (remember the trailing slash for webhook)

### GroupMe Integration
- **Real testing**: Use actual GROUPME_BOT_ID and GROUPME_GROUP_ID
- **Safe testing**: Use dummy values to avoid sending test messages

## Development Workflow

1. **Make changes** to `code/main.go`
2. **Restart server**: Stop with Ctrl+C, then `make run-local`
3. **Test changes**: Run `./test-local.sh` or manual curl commands
4. **Check logs**: Server outputs detailed logs for debugging

## Production Testing

To test with real GroupMe integration:

1. Set real environment variables
2. Start server: `GROUPME_BOT_ID=real-id GROUPME_GROUP_ID=real-id make run-local`
3. Configure GroupMe webhook to `http://your-ngrok-url/` (use ngrok for external access)
4. Send messages in GroupMe to test

## Files for Local Testing

- `test-local.sh` - Automated test script
- `.env.example` - Environment variable template
- `Makefile` - Contains `run-local`, `test-local`, and individual test targets

## Next Steps

After local testing works:
- Deploy to AWS: `make deploy`
- Deploy to GCP: `make deploy-gcp` 
- Set up GroupMe webhook with production URL