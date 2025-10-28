output "cloud_run_url" {
  description = "The URL of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.bot_service.uri
}

output "service_account_email" {
  description = "Email of the Cloud Run service account"
  value       = google_service_account.cloud_run_service_account.email
}

output "scheduler_service_account_email" {
  description = "Email of the Cloud Scheduler service account"
  value       = google_service_account.scheduler_service_account.email
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository for container images"
  value       = google_artifact_registry_repository.bot_repository.name
}

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}
