# GCP Deployment Guide for Goodwin ATX Bot

This guide walks you through deploying the Goodwin ATX Bot to Google Cloud Platform (GCP) using Cloud Run, Secret Manager, and Cloud Scheduler.

## Prerequisites

1. **GCP Account & Project**: Ensure you have a GCP account and a project created
2. **Local Tools**:
   - [Google Cloud CLI](https://cloud.google.com/sdk/docs/install)
   - [Docker](https://docs.docker.com/get-docker/)
   - [Terraform](https://www.terraform.io/downloads.html)
   - [Go](https://golang.org/doc/install) (1.24.7 or later)

3. **GroupMe Setup**:
   - GroupMe Bot ID
   - GroupMe Group ID

## Architecture Overview

The GCP deployment uses the following services:

- **Cloud Run**: Hosts the HTTP API for webhook processing
- **Secret Manager**: Securely stores GroupMe credentials
- **Cloud Scheduler**: Triggers weekly suggestions
- **Artifact Registry**: Stores container images
- **IAM**: Manages service accounts and permissions

## Quick Deployment

### 1. Clone and Configure

```bash
git clone https://github.com/ryan-Heard/goodwinATXBot.git
cd goodwinATXBot
git checkout gcp_infra
```

### 2. Set up GCP Authentication

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

### 3. Configure Terraform Variables

```bash
cd terraform/gcp
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

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

### 4. Deploy

```bash
cd ../..  # Back to project root
./deploy-gcp.sh YOUR_PROJECT_ID
```

Or deploy manually:

```bash
# Build and deploy
make docker-build PROJECT_ID=your-project-id
make docker-push PROJECT_ID=your-project-id
make init-gcp
make plan-gcp
make deploy-gcp
```

## Manual Deployment Steps

### 1. Enable GCP APIs

```bash
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### 2. Build and Push Container

```bash
# Build the Go application
make build-gcp

# Build Docker image
docker build -t gcr.io/YOUR_PROJECT_ID/goodwin-atx-bot:latest .

# Push to Container Registry
docker push gcr.io/YOUR_PROJECT_ID/goodwin-atx-bot:latest
```

### 3. Deploy Infrastructure

```bash
cd terraform/gcp
terraform init
terraform plan
terraform apply
```

### 4. Configure GroupMe Webhook

After deployment, configure your GroupMe bot webhook to point to the Cloud Run service URL:

```
https://YOUR_SERVICE_URL/
```

You can find the service URL in the Terraform output or by running:

```bash
gcloud run services describe goodwin-atx-bot --region=us-central1 --format="value(status.url)"
```

## Environment Variables

The application uses the following environment variables (configured automatically via Secret Manager):

- `GROUPME_BOT_ID`: Your GroupMe bot ID
- `GROUPME_GROUP_ID`: Your GroupMe group ID
- `PORT`: HTTP server port (set by Cloud Run)

## Monitoring and Logs

### View Logs

```bash
# Real-time logs
gcloud run services logs tail goodwin-atx-bot --region=us-central1

# Historical logs
gcloud run services logs read goodwin-atx-bot --region=us-central1
```

### Service Details

```bash
# Service information
gcloud run services describe goodwin-atx-bot --region=us-central1

# List all services
gcloud run services list
```

## Testing

### Health Check

```bash
curl https://YOUR_SERVICE_URL/health
```

### Manual Trigger (Weekly Suggestions)

```bash
curl -X POST https://YOUR_SERVICE_URL/scheduled \
  -H "Content-Type: application/json" \
  -d '{"source": "manual-test"}'
```

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure your service account has the correct IAM roles
2. **Secret Access**: Verify Secret Manager permissions
3. **Container Build**: Check Dockerfile and build logs

### Debug Commands

```bash
# Check service status
gcloud run services describe goodwin-atx-bot --region=us-central1

# View recent logs
gcloud run services logs read goodwin-atx-bot --region=us-central1 --limit=50

# Check secrets
gcloud secrets list

# Verify IAM bindings
gcloud projects get-iam-policy YOUR_PROJECT_ID
```

## Costs

Estimated monthly costs (with minimal usage):

- Cloud Run: ~$0-5 (pay per request)
- Secret Manager: ~$0.06 per secret per month
- Cloud Scheduler: ~$0.10 per job per month
- Artifact Registry: ~$0.10 per GB per month

Total estimated cost: **~$1-6 per month**

## Security

- Secrets are stored in Google Secret Manager
- Service accounts follow principle of least privilege
- Cloud Run service requires authentication for admin endpoints
- HTTPS is enforced by default

## Cleanup

To remove all resources:

```bash
make destroy-gcp
```

Or manually:

```bash
cd terraform/gcp
terraform destroy
```

## Support

For issues and questions:
1. Check the logs first
2. Verify GroupMe webhook configuration
3. Ensure all environment variables are set correctly
4. Review IAM permissions

## Architecture Diagram

```
GroupMe → Cloud Run ←→ Secret Manager
             ↑
     Cloud Scheduler
```

- GroupMe sends webhooks to Cloud Run
- Cloud Run processes messages and responds
- Cloud Scheduler triggers weekly suggestions
- Secret Manager provides secure credential access