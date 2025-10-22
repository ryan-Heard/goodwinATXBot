.PHONY: build clean deploy destroy init plan test

# Build the Lambda function for AWS Lambda (Linux)
build:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bootstrap main.go
	@echo "Build complete: bootstrap"

# Clean build artifacts
clean:
	rm -f bootstrap
	rm -f terraform/lambda_function.zip
	@echo "Clean complete"

# Initialize Terraform
init:
	cd terraform && terraform init

# Plan Terraform deployment
plan: build
	cd terraform && terraform plan

# Apply Terraform deployment
deploy: build
	cd terraform && terraform apply -auto-approve

# Destroy Terraform resources
destroy:
	cd terraform && terraform destroy -auto-approve

# Run tests
test:
	go test ./...

# Format Go code
fmt:
	go fmt ./...

# Vet Go code
vet:
	go vet ./...
