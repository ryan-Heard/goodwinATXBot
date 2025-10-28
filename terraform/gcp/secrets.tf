# Secret for GroupMe Bot ID
resource "google_secret_manager_secret" "groupme_bot_id" {
  secret_id = "${var.service_name}-groupme-bot-id"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager_api]
}

resource "google_secret_manager_secret_version" "groupme_bot_id" {
  secret      = google_secret_manager_secret.groupme_bot_id.id
  secret_data = var.groupme_bot_id
}

# Secret for GroupMe Group ID
resource "google_secret_manager_secret" "groupme_group_id" {
  secret_id = "${var.service_name}-groupme-group-id"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager_api]
}

resource "google_secret_manager_secret_version" "groupme_group_id" {
  secret      = google_secret_manager_secret.groupme_group_id.id
  secret_data = var.groupme_group_id
}

# IAM binding for the Cloud Run service account to access these specific secrets
resource "google_secret_manager_secret_iam_member" "groupme_bot_id_accessor" {
  secret_id = google_secret_manager_secret.groupme_bot_id.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

resource "google_secret_manager_secret_iam_member" "groupme_group_id_accessor" {
  secret_id = google_secret_manager_secret.groupme_group_id.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}
