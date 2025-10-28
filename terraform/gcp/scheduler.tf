# Cloud Scheduler job for weekly suggestions
resource "google_cloud_scheduler_job" "weekly_suggestions" {
  name             = "${var.service_name}-weekly-suggestions"
  description      = "Trigger weekly suggestions for Goodwin ATX Bot"
  schedule         = "0 10 * * 1" # Every Monday at 10 AM
  time_zone        = var.schedule_timezone
  attempt_deadline = "60s"

  retry_config {
    retry_count = 3
  }

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_v2_service.bot_service.uri}/scheduled"

    oidc_token {
      service_account_email = google_service_account.scheduler_service_account.email
      audience              = google_cloud_run_v2_service.bot_service.uri
    }

    headers = {
      "Content-Type" = "application/json"
    }

    body = base64encode(jsonencode({
      source = "cloud-scheduler"
      detail = {
        type = "weekly-suggestions"
      }
    }))
  }

  depends_on = [
    google_project_service.cloud_scheduler_api,
    google_cloud_run_v2_service.bot_service
  ]
}
