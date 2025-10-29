variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "us-south1"
}

variable "service_name" {
  description = "The name of the Cloud Run service"
  type        = string
  default     = "goodwin-atx-bot"
}

variable "groupme_bot_id" {
  description = "GroupMe Bot ID"
  type        = string
  sensitive   = true
}

variable "groupme_group_id" {
  description = "GroupMe Group ID"
  type        = string
  sensitive   = true
}

variable "container_image" {
  description = "Container image for the bot service"
  type        = string
  default     = "gcr.io/PROJECT_ID/goodwin-atx-bot:latest"
}

variable "schedule_timezone" {
  description = "Timezone for scheduled tasks"
  type        = string
  default     = "America/Chicago" # Austin, TX timezone
}
