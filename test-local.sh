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
export GROUPME_BOT_ID=${GROUPME_BOT_ID:-"test-bot-id"}
export GROUPME_GROUP_ID=${GROUPME_GROUP_ID:-"test-group-id"}

echo "PORT: $PORT"
echo "GROUPME_BOT_ID: $GROUPME_BOT_ID"
echo "GROUPME_GROUP_ID: $GROUPME_GROUP_ID"

# Build the application
echo "🔨 Building the application..."
go build -o bot-local code/main.go

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

echo ""
echo ""
echo "✅ All tests completed!"
echo "📋 Check the server logs above for detailed information"
echo "🔗 You can also visit http://localhost:$PORT/health in your browser"
echo ""
echo "Press Ctrl+C to stop the server..."

# Keep the script running until user stops it
wait $SERVER_PID