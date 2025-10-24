# Deployment Guide

This guide provides detailed instructions for deploying the Goodwin ATX Bot.

## Prerequisites

Before deploying, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured (`aws configure`)
3. **Terraform** (version 1.0+) installed
4. **Go** (version 1.21+) installed
5. **GroupMe Bot** created and configured

## Step-by-Step Deployment

### 1. Create GroupMe Bot

1. Visit [GroupMe Developer Portal](https://dev.groupme.com/bots)
2. Click "Create Bot"
3. Select your group
4. Set bot name (e.g., "Goodwin ATX Helper")
5. Optionally add an avatar URL
6. Click "Submit"
7. **Save your Bot ID** - you'll need this later

To find your Group ID:
- Open GroupMe web or app
- Navigate to your group
- The Group ID is in the URL: `https://web.groupme.com/groups/{GROUP_ID}`

### 2. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/ryan-Heard/goodwinATXBot.git
cd goodwinATXBot

# Create Terraform variables file
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform/terraform.tfvars`:
```hcl
groupme_bot_id   = "YOUR_BOT_ID_HERE"
groupme_group_id = "YOUR_GROUP_ID_HERE"
aws_region       = "us-east-1"  # or your preferred region
```

### 3. Build the Lambda Function

```bash
# Return to root directory
cd ..

# Build the binary
make build
```

This creates a `bootstrap` file optimized for AWS Lambda.

### 4. Deploy with Terraform

```bash
# Initialize Terraform (first time only)
make init

# Preview the deployment plan
make plan

# Deploy to AWS
make deploy
```

The deployment creates:
- Lambda function
- API Gateway for webhooks
- EventBridge rule for weekly suggestions
- IAM roles and permissions
- CloudWatch Log Groups

### 5. Configure GroupMe Webhook

After deployment, get your webhook URL:

```bash
cd terraform
terraform output api_gateway_url
```

Copy the output URL (e.g., `https://abcd1234.execute-api.us-east-1.amazonaws.com/webhook`)

Configure it in GroupMe:
1. Go to https://dev.groupme.com/bots
2. Click on your bot
3. Paste the API Gateway URL in the "Callback URL" field
4. Click "Submit"

### 6. Test the Deployment

**Test Question Response:**
1. Go to your GroupMe group
2. Send a message: "What time is the event?"
3. The bot should respond with a helpful message

**Test Weekly Suggestion:**
The bot will automatically send weekly suggestions based on the schedule (default: Mondays at 2 PM UTC).

To manually test, invoke the Lambda function:
```bash
aws lambda invoke \
  --function-name goodwin-atx-bot \
  --payload '{"path": "/scheduled"}' \
  response.json
```

### 7. Monitor the Bot

View logs in CloudWatch:
```bash
# Tail Lambda logs
aws logs tail /aws/lambda/goodwin-atx-bot --follow

# Or view in AWS Console
# Navigate to CloudWatch > Log groups > /aws/lambda/goodwin-atx-bot
```

## Customization

### Modify Weekly Schedule

Edit `terraform/variables.tf` and change the `schedule_expression` default:

```hcl
variable "schedule_expression" {
  default = "cron(0 18 ? * FRI *)"  # Friday at 6 PM UTC
}
```

Then redeploy:
```bash
make deploy
```

### Update Bot Responses

Edit `main.go`:
- `generateQuestionResponse()` - customize question responses
- `generateWeeklySuggestion()` - customize weekly messages

After changes:
```bash
make build
make deploy
```

## Troubleshooting

### Bot not responding to questions

**Check webhook configuration:**
```bash
curl -X POST https://your-api-gateway-url/webhook \
  -H "Content-Type: application/json" \
  -d '{"text":"test?","sender_type":"user","group_id":"12345"}'
```

**Check Lambda logs:**
```bash
aws logs tail /aws/lambda/goodwin-atx-bot --follow
```

**Verify environment variables:**
```bash
aws lambda get-function-configuration \
  --function-name goodwin-atx-bot \
  --query 'Environment.Variables'
```

### Weekly suggestions not sending

**Check EventBridge rule:**
```bash
aws events describe-rule --name goodwin-atx-bot-weekly
```

**Verify the rule is enabled:**
```bash
aws events list-targets-by-rule --rule goodwin-atx-bot-weekly
```

**Manually trigger:**
```bash
aws lambda invoke \
  --function-name goodwin-atx-bot \
  --payload '{"path":"/scheduled"}' \
  response.json && cat response.json
```

### Permission errors

Ensure your AWS credentials have permissions for:
- Lambda (create, update, invoke)
- API Gateway (create, manage)
- EventBridge (create rules, targets)
- IAM (create roles, attach policies)
- CloudWatch Logs (create groups, streams)

## Updating the Bot

To update the bot code:

```bash
# Make your changes to main.go
# ...

# Rebuild and redeploy
make build
make deploy
```

To update Terraform infrastructure:

```bash
# Modify terraform/*.tf files
# ...

# Review changes
make plan

# Apply changes
make deploy
```

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

**Important:** This will permanently delete:
- Lambda function
- API Gateway
- EventBridge rules
- CloudWatch Logs (if retention period has passed)

The GroupMe bot configuration will remain but won't function without the Lambda backend.

## Cost Management

### Expected Costs

With typical usage (< 1000 messages/day):
- **Lambda**: Free tier covers first 1M requests
- **API Gateway**: Free tier covers first 1M requests  
- **EventBridge**: Free tier covers scheduled events
- **CloudWatch Logs**: Free tier covers 5GB

**Estimated monthly cost:** $0-5

### Monitor Costs

```bash
# Check current month's costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d "1 month ago" +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --filter file://filter.json
```

### Reduce Costs

1. **Reduce log retention:**
   - Edit `terraform/lambda.tf` and `terraform/api_gateway.tf`
   - Change `retention_in_days` from 14 to 7 or 3

2. **Optimize Lambda memory:**
   - Edit `terraform/lambda.tf`
   - Test with lower `memory_size` (128 MB is already optimal)

## Security Best Practices

1. **Never commit `terraform.tfvars`** - contains sensitive bot IDs
2. **Rotate bot credentials** periodically via GroupMe portal
3. **Monitor CloudWatch Logs** for suspicious activity
4. **Use AWS IAM roles** with minimum required permissions
5. **Enable AWS CloudTrail** for audit logging
6. **Set up billing alerts** in AWS Console

## Support

For issues or questions:
- Check CloudWatch Logs first
- Review the [main README](../README.md)
- Open an issue on GitHub
