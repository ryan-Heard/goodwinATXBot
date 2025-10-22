# goodwinATXBot

A GroupMe bot designed to help users with questions and provide weekly suggestions for the Goodwin ATX community. Built with Go and deployed to AWS Lambda using Terraform.

## Features

- **Question Answering**: Automatically responds to questions in the GroupMe chat
- **Weekly Suggestions**: Sends scheduled weekly suggestions every Monday at 2 PM UTC
- **Serverless Architecture**: Runs on AWS Lambda for cost-effective, scalable operation
- **Infrastructure as Code**: Fully managed with Terraform for easy deployment and maintenance

## Architecture

The bot consists of:
- **Go Application**: Lambda function that handles both webhook callbacks and scheduled events
- **API Gateway**: HTTP endpoint for receiving GroupMe webhook callbacks
- **EventBridge**: Scheduler for sending weekly suggestions
- **CloudWatch Logs**: Logging for monitoring and debugging

## Prerequisites

- Go 1.21 or later
- Terraform 1.0 or later
- AWS CLI configured with appropriate credentials
- A GroupMe account and bot created via [GroupMe Developer Portal](https://dev.groupme.com/)

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

### 3. Configure Terraform Variables

Create a `terraform.tfvars` file in the `terraform/` directory:

```hcl
groupme_bot_id   = "your-groupme-bot-id"
groupme_group_id = "your-groupme-group-id"
aws_region       = "us-east-1"  # Optional, defaults to us-east-1
```

**Note**: Never commit this file to version control as it contains sensitive information.

### 4. Build and Deploy

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
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bootstrap main.go

# Deploy with Terraform
cd terraform
terraform init
terraform plan
terraform apply
```

### 5. Configure GroupMe Webhook

After deployment, Terraform will output the API Gateway URL. Configure this as your GroupMe bot's callback URL:

1. Get the webhook URL from Terraform output:
   ```bash
   cd terraform
   terraform output api_gateway_url
   ```

2. Update your GroupMe bot's callback URL at https://dev.groupme.com/bots
   - Set the callback URL to the output from step 1

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

Edit the `generateQuestionResponse()` function in `main.go` to customize how the bot responds to questions.

### Modifying Weekly Suggestions

Edit the `generateWeeklySuggestion()` function in `main.go` to customize weekly suggestion messages.

## Cost Estimation

With AWS Free Tier:
- Lambda: First 1M requests/month free, then $0.20 per 1M requests
- API Gateway: First 1M requests/month free, then $1.00 per 1M requests
- EventBridge: First 14M events/month free (scheduled events included)
- CloudWatch Logs: 5GB ingestion and storage free

Expected monthly cost for typical usage: **$0 - $5/month**

## Cleanup

To remove all AWS resources:

```bash
make destroy
```

Or manually:

```bash
cd terraform
terraform destroy
```

## Troubleshooting

### Bot not responding

1. Check CloudWatch Logs:
   ```bash
   aws logs tail /aws/lambda/goodwin-atx-bot --follow
   ```

2. Verify the webhook URL is correctly configured in GroupMe

3. Ensure environment variables are set correctly in Lambda

### Weekly suggestions not sending

1. Check EventBridge rule is enabled
2. Verify the schedule expression is correct
3. Check CloudWatch Logs for errors

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use this bot for your own communities!