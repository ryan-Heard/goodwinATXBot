.PHONY: build clean deploy destroy init plan test build-gcp deploy-gcp destroy-gcp docker-build docker-push

# Variables
PROJECT_ID ?= your-gcp-project-id
REGION ?= us-central1
SERVICE_NAME ?= goodwin-atx-bot
IMAGE_TAG ?= latest

# Build the Lambda function for AWS Lambda (Linux)
build:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bootstrap ./code
	@echo "Build complete: bootstrap"

# Build for GCP Cloud Run
build-gcp:
	CGO_ENABLED=0 GOOS=linux go build -o main ./code
	@echo "Build complete for GCP: main"

# Build Docker image for GCP Cloud Run
docker-build: build-gcp
	docker build -t gcr.io/$(PROJECT_ID)/$(SERVICE_NAME):$(IMAGE_TAG) .
	@echo "Docker image built: gcr.io/$(PROJECT_ID)/$(SERVICE_NAME):$(IMAGE_TAG)"

# Push Docker image to Google Container Registry
docker-push: docker-build
	docker push gcr.io/$(PROJECT_ID)/$(SERVICE_NAME):$(IMAGE_TAG)
	@echo "Docker image pushed: gcr.io/$(PROJECT_ID)/$(SERVICE_NAME):$(IMAGE_TAG)"

# Clean build artifacts
clean:
	rm -f bootstrap main
	rm -f terraform/aws/lambda_function.zip
	@echo "Clean complete"

# Initialize Terraform for AWS
init:
	cd terraform/aws && terraform init

# Initialize Terraform for GCP
init-gcp:
	cd terraform/gcp && terraform init

# Plan Terraform deployment for AWS
plan: build
	cd terraform/aws && terraform plan

# Plan Terraform deployment for GCP
plan-gcp:
	cd terraform/gcp && terraform plan

# Apply Terraform deployment for AWS
deploy: build
	cd terraform/aws && terraform apply -auto-approve

# Apply Terraform deployment for GCP
deploy-gcp:
	cd terraform/gcp && terraform apply -auto-approve

# Destroy Terraform resources for AWS
destroy:
	cd terraform/aws && terraform destroy -auto-approve

# Destroy Terraform resources for GCP
destroy-gcp:
	cd terraform/gcp && terraform destroy -auto-approve

# Run unit tests
test:
	@echo "Running unit tests..."
	go test ./code -v

# Run unit tests with coverage
test-coverage:
	@echo "Running unit tests with coverage..."
	go test ./code -v -cover

# Run all tests (unit + integration)
test-all: test test-local

# Run local server for testing
test-local:
	@echo "Starting local test server..."
	@echo "Set GROUPME_BOT_ID and GROUPME_GROUP_ID environment variables for real GroupMe integration"
	@echo "Or use dummy values for safe testing"
	./test-local.sh

# Run server locally without tests
run-local:
	@echo "Starting local server on port 8080..."
	@echo "Visit http://localhost:8080/health to check status"
	@echo "Press Ctrl+C to stop"
	PORT=8080 go run ./code

# Test individual endpoints with curl
test-health:
	@echo "Testing health endpoint..."
	@curl -s http://localhost:8080/health | jq . || curl -s http://localhost:8080/health

test-webhook:
	@echo "Testing webhook with sample question..."
	@curl -s -X POST http://localhost:8080/ \
		-H "Content-Type: application/json" \
		-d '{"text": "What is happening?", "sender_type": "user", "group_id": "test-group", "name": "Test User"}'

test-schedule:
	@echo "Testing scheduled endpoint..."
	@curl -s -X POST http://localhost:8080/scheduled \
		-H "Content-Type: application/json"

# Format Go code
fmt:
	go fmt ./...

# Vet Go code
vet:
	go vet ./...
