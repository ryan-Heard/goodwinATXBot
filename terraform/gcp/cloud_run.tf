# Artifact Registry Repository for container images
resource "google_artifact_registry_repository" "bot_repository" {
  location      = var.region
  repository_id = var.service_name
  description   = "Repository for Goodwin ATX Bot container images"
  format        = "DOCKER"

  depends_on = [google_project_service.artifact_registry_api]
}

# Cloud Run service
resource "google_cloud_run_v2_service" "bot_service" {
  name     = var.service_name
  location = var.region

  template {
    service_account = google_service_account.cloud_run_service_account.email

    containers {
      image = replace(var.container_image, "PROJECT_ID", var.project_id)

      # Environment variables that reference secrets
      env {
        name = "GROUPME_BOT_ID"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.groupme_bot_id.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "GROUPME_GROUP_ID"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.groupme_group_id.secret_id
            version = "latest"
          }
        }
      }

      # Resource limits
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
        cpu_idle = true
      }

      ports {
        container_port = 8080
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }

    # Timeout for requests
    timeout = "30s"
  }

  traffic {
    percent = 100
  }

  depends_on = [
    google_project_service.cloud_run_api,
    google_secret_manager_secret_version.groupme_bot_id,
    google_secret_manager_secret_version.groupme_group_id
  ]
}

# Allow unauthenticated requests to the Cloud Run service (for GroupMe webhooks)
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_v2_service.bot_service.name
  location = google_cloud_run_v2_service.bot_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
