#!/bin/bash

# GCP Deployment Script for Goodwin ATX Bot
# This script deploys the bot to Google Cloud Platform

set -e

# Configuration
PROJECT_ID=${1:-"your-gcp-project-id"}
REGION=${2:-"us-central1"}
SERVICE_NAME=${3:-"goodwin-atx-bot"}
IMAGE_TAG=${4:-"latest"}

echo "🚀 Starting GCP deployment for Goodwin ATX Bot..."
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Service Name: $SERVICE_NAME"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed. Please install it first."
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install it first."
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Set the current project
echo "🔧 Setting GCP project..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "📡 Enabling required GCP APIs..."
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Configure Docker for GCR
echo "🐳 Configuring Docker for Google Container Registry..."
gcloud auth configure-docker gcr.io

# Build the application
echo "🔨 Building the application..."
make build-gcp

# Build and push Docker image
echo "📦 Building and pushing Docker image..."
make docker-build PROJECT_ID=$PROJECT_ID SERVICE_NAME=$SERVICE_NAME IMAGE_TAG=$IMAGE_TAG
make docker-push PROJECT_ID=$PROJECT_ID SERVICE_NAME=$SERVICE_NAME IMAGE_TAG=$IMAGE_TAG

# Initialize Terraform
echo "🏗️  Initializing Terraform..."
make init-gcp

# Check if terraform.tfvars exists
if [ ! -f "terraform/gcp/terraform.tfvars" ]; then
    echo "⚠️  terraform.tfvars not found. Please create it from terraform.tfvars.example"
    echo "   and update the values with your GCP project ID and GroupMe credentials."
    echo ""
    echo "   cd terraform/gcp"
    echo "   cp terraform.tfvars.example terraform.tfvars"
    echo "   # Edit terraform.tfvars with your values"
    exit 1
fi

# Plan deployment
echo "📋 Planning Terraform deployment..."
make plan-gcp

# Ask for confirmation
echo ""
read -p "🤔 Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Deploying infrastructure..."
    make deploy-gcp
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Note the Cloud Run service URL from the Terraform output"
    echo "2. Configure your GroupMe bot webhook to point to the service URL"
    echo "3. Test the bot by sending a message to your GroupMe group"
    echo ""
    echo "🔍 To view logs: gcloud run services logs read $SERVICE_NAME --region=$REGION"
    echo "🌐 To view service: gcloud run services describe $SERVICE_NAME --region=$REGION"
else
    echo "❌ Deployment cancelled"
    exit 1
fi