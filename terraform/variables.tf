variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
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

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "goodwin-atx-bot"
}

variable "schedule_expression" {
  description = "EventBridge schedule expression for weekly suggestions"
  type        = string
  default     = "cron(0 14 ? * MON *)" # Every Monday at 2 PM UTC
}
