#!/bin/bash

# Local testing script for Goodwin ATX Bot
# This script helps test the bot functionality locally

set -e

echo "🧪 Local Testing for Goodwin ATX Bot"
echo "===================================="

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go first."
    exit 1
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "❌ curl is not available. Please install curl first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Set up environment variables for local testing
echo "🔧 Setting up environment variables..."
export PORT=8080

# Check if real GroupMe credentials are available
if [ -f ".env" ] && grep -q "GROUPME_BOT_ID.*[^=]$" .env 2>/dev/null; then
    echo "📡 Loading real GroupMe credentials from .env file..."
    source .env
    export REAL_GROUPME_API=true
else
    echo "🧪 Using test credentials (API calls will fail - this is expected)"
    echo "   To test with real GroupMe API, create a .env file with real credentials"
    export GROUPME_BOT_ID=test-bot-id
    export GROUPME_GROUP_ID=test-group-id
    export REAL_GROUPME_API=false
fi

echo "PORT: $PORT"
echo "GROUPME_BOT_ID: $GROUPME_BOT_ID"
echo "GROUPME_GROUP_ID: $GROUPME_GROUP_ID"

# Build the application
echo "🔨 Building the application..."
go build -o bot-local ./code

# Start the server in background
echo "🚀 Starting the server..."
./bot-local &
SERVER_PID=$!

# Wait for server to start
sleep 2

echo "📡 Server started with PID: $SERVER_PID"
echo "🌐 Server is running at: http://localhost:$PORT"

# Function to cleanup
cleanup() {
    echo "🧹 Cleaning up..."
    kill $SERVER_PID 2>/dev/null || true
    rm -f bot-local
    exit
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Test health endpoint
echo ""
echo "🔍 Testing health endpoint..."
curl -s http://localhost:$PORT/health | jq . || echo "Health check response (raw):"

# Test GroupMe webhook with sample data
echo ""
echo "🔍 Testing GroupMe webhook with sample question..."
if [ "$REAL_GROUPME_API" = "false" ]; then
    echo "   ⚠️  Expected: API errors (400/404) due to test credentials"
fi
curl -s -X POST http://localhost:$PORT/ \
  -H "Content-Type: application/json" \
  -d '{
    "attachments": [],
    "avatar_url": "https://example.com/avatar.jpg",
    "created_at": 1635724800,
    "group_id": "test-group-123",
    "id": "msg-456",
    "name": "Test User",
    "sender_id": "user-789",
    "sender_type": "user",
    "source_guid": "guid-abc",
    "system": false,
    "text": "What is happening this week?",
    "user_id": "user-789"
  }'

echo ""

# Test weekly suggestions endpoint
echo ""
echo "🔍 Testing weekly suggestions endpoint..."
if [ "$REAL_GROUPME_API" = "false" ]; then
    echo "   ⚠️  Expected: API errors (400/404) due to test credentials"
fi
curl -s -X POST http://localhost:$PORT/scheduled \
  -H "Content-Type: application/json" \
  -d '{"source": "manual-test"}'

echo ""

# Test with non-question message
echo ""
echo "🔍 Testing with non-question message..."
curl -s -X POST http://localhost:$PORT/ \
  -H "Content-Type: application/json" \
  -d '{
    "attachments": [],
    "avatar_url": "https://example.com/avatar.jpg",
    "created_at": 1635724800,
    "group_id": "test-group-123",
    "id": "msg-457",
    "name": "Test User",
    "sender_id": "user-789",
    "sender_type": "user",
    "source_guid": "guid-abc",
    "system": false,
    "text": "Hello everyone!",
    "user_id": "user-789"
  }'

echo ""

# Test with bot message (should be ignored)
echo ""
echo "🔍 Testing with bot message (should be ignored)..."
curl -s -X POST http://localhost:$PORT/ \
  -H "Content-Type: application/json" \
  -d '{
    "attachments": [],
    "avatar_url": "https://example.com/avatar.jpg",
    "created_at": 1635724800,
    "group_id": "test-group-123",
    "id": "msg-458",
    "name": "Bot",
    "sender_id": "bot-123",
    "sender_type": "bot",
    "source_guid": "guid-def",
    "system": false,
    "text": "I am a bot message",
    "user_id": "bot-123"
  }'

# Test for a mesasage about guest parking
echo ""
echo "🔍 Testing for a message about guest parking..."
curl -s -X POST http://localhost:$PORT/ \
  -H "Content-Type: application/json" \
  -d '{
    "attachments": [],
    "avatar_url": "https://example.com/avatar.jpg",
    "created_at": 1635724800,
    "group_id": "test-group-123",
    "id": "msg-459",
    "name": "Test User",
    "sender_id": "user-789",
    "sender_type": "user",
    "source_guid": "guid-ghi",
    "system": false,
    "text": "Where can I find guest parking code?",
    "user_id": "user-789"
  }'

echo ""

# Test different question types
echo ""
echo "🔍 Testing various question types..."

# Test "what" question
echo "Testing 'what' question:"
curl -s -X POST http://localhost:$PORT/ \
  -H "Content-Type: application/json" \
  -d '{
    "attachments": [],
    "avatar_url": "https://example.com/avatar.jpg",
    "created_at": 1635724800,
    "group_id": "test-group-123",
    "id": "msg-460",
    "name": "Test User",
    "sender_id": "user-789",
    "sender_type": "user",
    "source_guid": "guid-jkl",
    "system": false,
    "text": "What time does the event start?",
    "user_id": "user-789"
  }'

echo ""

# Test "when" question
echo "Testing 'when' question:"
curl -s -X POST http://localhost:$PORT/ \
  -H "Content-Type: application/json" \
  -d '{
    "attachments": [],
    "avatar_url": "https://example.com/avatar.jpg",
    "created_at": 1635724800,
    "group_id": "test-group-123",
    "id": "msg-461",
    "name": "Test User",
    "sender_id": "user-789",
    "sender_type": "user",
    "source_guid": "guid-mno",
    "system": false,
    "text": "When is the next meeting?",
    "user_id": "user-789"
  }'

echo ""

# Test "how" question
echo "Testing 'how' question:"
curl -s -X POST http://localhost:$PORT/ \
  -H "Content-Type: application/json" \
  -d '{
    "attachments": [],
    "avatar_url": "https://example.com/avatar.jpg",
    "created_at": 1635724800,
    "group_id": "test-group-123",
    "id": "msg-462",
    "name": "Test User",
    "sender_id": "user-789",
    "sender_type": "user",
    "source_guid": "guid-pqr",
    "system": false,
    "text": "How do I register for events?",
    "user_id": "user-789"
  }'

echo ""

# Test edge cases
echo ""
echo "🔍 Testing edge cases..."

# Test empty message
echo "Testing empty message:"
curl -s -X POST http://localhost:$PORT/ \
  -H "Content-Type: application/json" \
  -d '{
    "attachments": [],
    "avatar_url": "https://example.com/avatar.jpg",
    "created_at": 1635724800,
    "group_id": "test-group-123",
    "id": "msg-463",
    "name": "Test User",
    "sender_id": "user-789",
    "sender_type": "user",
    "source_guid": "guid-stu",
    "system": false,
    "text": "",
    "user_id": "user-789"
  }'

echo ""

# Test malformed JSON
echo "Testing malformed JSON handling:"
curl -s -X POST http://localhost:$PORT/ \
  -H "Content-Type: application/json" \
  -d '{"invalid": json}'

echo ""

# Test GET request (should fail)
echo "Testing GET request (should return 405):"
curl -s -X GET http://localhost:$PORT/

echo ""

# Test invalid endpoint
echo "Testing invalid endpoint:"
curl -s http://localhost:$PORT/invalid-endpoint

echo ""

# Test system message (should be ignored)
echo "Testing system message (should be ignored):"
curl -s -X POST http://localhost:$PORT/ \
  -H "Content-Type: application/json" \
  -d '{
    "attachments": [],
    "avatar_url": "",
    "created_at": 1635724800,
    "group_id": "test-group-123",
    "id": "msg-464",
    "name": "System",
    "sender_id": "system",
    "sender_type": "system",
    "source_guid": "guid-vwx",
    "system": true,
    "text": "User joined the group",
    "user_id": "system"
  }'

echo ""

# Performance test - multiple rapid requests
echo ""
echo "🔍 Performance testing - multiple rapid requests..."
for i in {1..5}; do
  echo "Request $i:"
  curl -s -X POST http://localhost:$PORT/ \
    -H "Content-Type: application/json" \
    -d "{
      \"attachments\": [],
      \"avatar_url\": \"https://example.com/avatar.jpg\",
      \"created_at\": 1635724800,
      \"group_id\": \"test-group-123\",
      \"id\": \"msg-${i}\",
      \"name\": \"Test User $i\",
      \"sender_id\": \"user-${i}\",
      \"sender_type\": \"user\",
      \"source_guid\": \"guid-${i}\",
      \"system\": false,
      \"text\": \"Test message $i\",
      \"user_id\": \"user-${i}\"
    }" &
done

# Wait for background requests to complete
sleep 2

echo ""
echo ""
echo "🔬 Running Go unit tests..."
cd /Users/black/personal/goodwinATXBot
go test ./code -v

echo ""
echo "📊 Running tests with coverage..."
go test ./code -cover

echo ""
echo "⚡ Running benchmark tests..."
go test ./code -bench=. -benchmem

echo ""
echo ""
echo "✅ All tests completed!"
echo "📋 Check the server logs above for detailed information"
echo "🔗 You can also visit http://localhost:$PORT/health in your browser"
echo ""
echo "Press Ctrl+C to stop the server..."

# Keep the script running until user stops it
wait $SERVER_PID