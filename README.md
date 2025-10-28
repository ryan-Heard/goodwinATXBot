# goodwinATXBot

A GroupMe bot designed to help users with questions and provide weekly suggestions for the Goodwin ATX community. Built with Go and deployable to both AWS Lambda and Google Cloud Platform using Terraform.

## Features

- **Question Answering**: Automatically responds to questions in the GroupMe chat
- **Weekly Suggestions**: Sends scheduled weekly suggestions every Monday at 10 AM Central Time
- **Multi-Cloud Support**: Deploy to AWS Lambda or Google Cloud Run
- **Serverless Architecture**: Pay-per-use pricing on both AWS and GCP
- **Infrastructure as Code**: Fully managed with Terraform for easy deployment and maintenance
- **Container-Ready**: Docker support for GCP Cloud Run deployment

## Architecture

### AWS Architecture
- **Go Application**: Lambda function that handles both webhook callbacks and scheduled events
- **API Gateway**: HTTP endpoint for receiving GroupMe webhook callbacks
- **EventBridge**: Scheduler for sending weekly suggestions
- **CloudWatch Logs**: Logging for monitoring and debugging

### GCP Architecture
- **Go Application**: Containerized HTTP server running on Cloud Run
- **Cloud Run**: Serverless container platform with auto-scaling
- **Cloud Scheduler**: Cron-based scheduler for weekly suggestions
- **Secret Manager**: Secure storage for GroupMe credentials
- **Cloud Logging**: Centralized logging and monitoring

## Prerequisites

- Go 1.24.7 or later
- Terraform 1.0 or later
- A GroupMe account and bot created via [GroupMe Developer Portal](https://dev.groupme.com/)

### For AWS Deployment
- AWS CLI configured with appropriate credentials

### For GCP Deployment  
- Google Cloud CLI (`gcloud`) configured with appropriate credentials
- Docker installed for container building

## Setup

### 1. Create a GroupMe Bot

1. Go to https://dev.groupme.com/bots
2. Click "Create Bot"
3. Select the group where you want the bot
4. Give your bot a name (e.g., "Goodwin ATX Helper")
5. Save the **Bot ID** and **Group ID** for later

### 2. Clone the Repository

```bash
git clone https://github.com/ryan-Heard/goodwinATXBot.git
cd goodwinATXBot
```

### 3. Choose Your Deployment Platform

- **AWS Lambda**: See [AWS Deployment](#aws-deployment) section below
- **Google Cloud Run**: See [GCP Deployment](#gcp-deployment) section below

## AWS Deployment

### 1. Configure Terraform Variables

Create a `terraform.tfvars` file in the `terraform/aws/` directory:

```hcl
groupme_bot_id   = "your-groupme-bot-id"
groupme_group_id = "your-groupme-group-id"
aws_region       = "us-east-1"  # Optional, defaults to us-east-1
```

**Note**: Never commit this file to version control as it contains sensitive information.

### 2. Build and Deploy

Using the Makefile:

```bash
# Build the Lambda function
make build

# Initialize Terraform
make init

# Preview the deployment
make plan

# Deploy to AWS
make deploy
```

Or manually:

```bash
# Build the Go binary for Lambda
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bootstrap code/main.go

# Deploy with Terraform
cd terraform/aws
terraform init
terraform plan
terraform apply
```

### 3. Configure GroupMe Webhook

After deployment, Terraform will output the API Gateway URL. Configure this as your GroupMe bot's callback URL:

1. Get the webhook URL from Terraform output:
   ```bash
   cd terraform/aws
   terraform output api_gateway_url
   ```

2. Update your GroupMe bot's callback URL at https://dev.groupme.com/bots
   - Set the callback URL to the output from step 1

## GCP Deployment

### 1. Quick Start

For a complete automated deployment, see the detailed [GCP Deployment Guide](GCP_DEPLOYMENT.md).

```bash
# Switch to GCP branch
git checkout gcp_infra

# Configure GCP project
gcloud config set project your-gcp-project-id

# Run automated deployment
./deploy-gcp.sh your-gcp-project-id
```

### 2. Manual GCP Setup

1. **Configure Terraform Variables**

   Create a `terraform.tfvars` file in the `terraform/gcp/` directory:

   ```hcl
   project_id = "your-gcp-project-id"
   region     = "us-central1"
   
   # GroupMe Configuration
   groupme_bot_id    = "your-groupme-bot-id"
   groupme_group_id  = "your-groupme-group-id"
   
   # Optional customizations
   service_name      = "goodwin-atx-bot"
   schedule_timezone = "America/Chicago"
   ```

2. **Build and Deploy**

   ```bash
   # Build and deploy to GCP
   make build-gcp
   make docker-build PROJECT_ID=your-project-id
   make docker-push PROJECT_ID=your-project-id
   make init-gcp
   make deploy-gcp
   ```

3. **Configure GroupMe Webhook**

   After deployment, get the Cloud Run service URL:
   ```bash
   gcloud run services describe goodwin-atx-bot --region=us-central1 --format="value(status.url)"
   ```

   Set this URL as your GroupMe bot's callback URL at https://dev.groupme.com/bots

### GCP Cost Estimation

With minimal usage:
- Cloud Run: ~$0-5/month (pay per request)
- Secret Manager: ~$0.06/month per secret
- Cloud Scheduler: ~$0.10/month per job
- Artifact Registry: ~$0.10/month per GB

**Expected monthly cost: $1-6/month**

## Development

### Run Tests

```bash
make test
```

### Format Code

```bash
make fmt
```

### Vet Code

```bash
make vet
```

### Local Testing

To test the Lambda function locally, you can use the AWS SAM CLI or invoke it with test events.

## Configuration

### Environment Variables

The following environment variables are configured in the Lambda function:

- `GROUPME_BOT_ID`: Your GroupMe bot ID (set via Terraform)
- `GROUPME_GROUP_ID`: Your GroupMe group ID (set via Terraform)

### Schedule Configuration

To change the weekly suggestion schedule, modify the `schedule_expression` variable in `terraform/variables.tf`. 

Examples:
- `cron(0 14 ? * MON *)` - Every Monday at 2 PM UTC
- `cron(0 12 ? * FRI *)` - Every Friday at 12 PM UTC
- `rate(7 days)` - Every 7 days

See [AWS EventBridge Schedule Expressions](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html) for more options.

## Customization

### Modifying Question Responses

Edit the `generateQuestionResponse()` function in `code/main.go` to customize how the bot responds to questions.

### Modifying Weekly Suggestions

Edit the `generateWeeklySuggestion()` function in `code/main.go` to customize weekly suggestion messages.

## Cost Estimation

With AWS Free Tier:
- Lambda: First 1M requests/month free, then $0.20 per 1M requests
- API Gateway: First 1M requests/month free, then $1.00 per 1M requests
- EventBridge: First 14M events/month free (scheduled events included)
- CloudWatch Logs: 5GB ingestion and storage free

Expected monthly cost for typical usage: **$0 - $5/month**

## Cleanup

### AWS Resources
```bash
make destroy
# Or manually: cd terraform/aws && terraform destroy
```

### GCP Resources
```bash
make destroy-gcp
# Or manually: cd terraform/gcp && terraform destroy
```

## Troubleshooting

### Bot not responding

**AWS:**
1. Check CloudWatch Logs:
   ```bash
   aws logs tail /aws/lambda/goodwin-atx-bot --follow
   ```
2. Verify the webhook URL is correctly configured in GroupMe
3. Ensure environment variables are set correctly in Lambda

**GCP:**
1. Check Cloud Run logs:
   ```bash
   gcloud run services logs read goodwin-atx-bot --region=us-central1
   ```
2. Verify the webhook URL is correctly configured in GroupMe
3. Ensure secrets are accessible in Secret Manager

### Weekly suggestions not sending

**AWS:**
1. Check EventBridge rule is enabled
2. Verify the schedule expression is correct
3. Check CloudWatch Logs for errors

**GCP:**
1. Check Cloud Scheduler job status:
   ```bash
   gcloud scheduler jobs describe goodwin-atx-bot-weekly-suggestions --location=us-central1
   ```
2. Verify the schedule expression is correct
3. Check Cloud Run logs for errors

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use this bot for your own communities!