terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "secret_manager_api" {
  service = "secretmanager.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "cloud_scheduler_api" {
  service = "cloudscheduler.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "artifact_registry_api" {
  service = "artifactregistry.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "cloud_build_api" {
  service = "cloudbuild.googleapis.com"

  disable_dependent_services = true
}
