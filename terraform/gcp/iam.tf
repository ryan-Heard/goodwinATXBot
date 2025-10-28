# Service Account for Cloud Run
resource "google_service_account" "cloud_run_service_account" {
  account_id   = "${var.service_name}-sa"
  display_name = "Cloud Run Service Account for ${var.service_name}"
  description  = "Service account for the Goodwin ATX Bot Cloud Run service"
}

# Service Account for Cloud Scheduler
resource "google_service_account" "scheduler_service_account" {
  account_id   = "${var.service_name}-scheduler-sa"
  display_name = "Cloud Scheduler Service Account for ${var.service_name}"
  description  = "Service account for the Cloud Scheduler to invoke Cloud Run"
}

# IAM binding for Cloud Run service account to access Secret Manager
resource "google_project_iam_member" "cloud_run_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

# IAM binding for Cloud Scheduler to invoke Cloud Run
resource "google_project_iam_member" "scheduler_cloud_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.scheduler_service_account.email}"
}

# IAM binding for Cloud Run service account to write logs
resource "google_project_iam_member" "cloud_run_logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}
