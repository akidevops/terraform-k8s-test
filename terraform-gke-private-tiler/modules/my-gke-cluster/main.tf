resource "google_container_cluster" "cluster" {
  provider           = google
  name               = var.name
  description        = var.description
  project            = var.project
  location           = var.location
  network            = var.network
  subnetwork         = var.subnetwork
  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service
  min_master_version = local.kubernetes_version
  # This leaves us with a cluster master with no node pools.
  remove_default_node_pool = true
  # we need to set an initial_node_count of 1
  initial_node_count = 1

  # If we have an alternative default service account to use, set on the node_config
  dynamic "node_config" {
    for_each = [
      for x in [var.alternative_default_service_account] : x if var.alternative_default_service_account != null
    ]
    content {
      service_account = node_config.value
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.cluster_secondary_range_name
  }

  # This is to make GKE Cluster Private
  private_cluster_config {
    enable_private_endpoint = var.disable_public_endpoint
    enable_private_nodes    = var.enable_private_nodes
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  addons_config {
    http_load_balancing {
      disabled = ! var.http_load_balancing
    }

    horizontal_pod_autoscaling {
      disabled = ! var.horizontal_pod_autoscaling
    }

    kubernetes_dashboard {
      disabled = ! var.enable_kubernetes_dashboard
    }

    network_policy_config {
      disabled = ! var.enable_network_policy
    }
  }

  network_policy {
    enabled  = var.enable_network_policy
    provider = "CALICO"
  }

  master_auth {
    username = var.basic_auth_username
    password = var.basic_auth_password
    client_certificate_config {
      issue_client_certificate = var.enable_kubernetes_dashboard
    }
  }

  dynamic "master_authorized_networks_config" {
    for_each = var.master_authorized_networks_config
    content {
      dynamic "cidr_blocks" {
        for_each = lookup(master_authorized_networks_config.value, "cidr_blocks", [])
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = lookup(cidr_blocks.value, "display_name", null)
        }
      }
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  lifecycle {
    ignore_changes = [
      node_config,
    ]
  }
}