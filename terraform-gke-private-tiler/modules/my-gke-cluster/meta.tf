terraform {
  required_version = ">= 0.12.6"
}

data "google_container_engine_versions" "location" {
  location = var.location
  project  = var.project
}

locals {
  latest_version     = data.google_container_engine_versions.location.latest_master_version
  kubernetes_version = var.kubernetes_version != "latest" ? var.kubernetes_version : local.latest_version
  network_project    = var.network_project != "" ? var.network_project : var.project
}