# GKE CLuster

module "gke_cluster" {
  source = "./modules/my-gke-cluster"

  name                    = var.cluster_name
  project                 = var.project
  location                = var.location
  network                 = module.vpc_network.network
  subnetwork              = module.vpc_network.public_subnetwork
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  enable_private_nodes    = "true"
  disable_public_endpoint = "false"
  master_authorized_networks_config = [
    {
      cidr_blocks = [
        {
          cidr_block   = "0.0.0.0/0"
          display_name = "all-for-testing"
        },
      ]
    },
  ]
  cluster_secondary_range_name = module.vpc_network.public_subnetwork_secondary_range_name
}

# Node Pool

resource "google_container_node_pool" "node_pool" {
  provider = google

  name     = "private-pool"
  project  = var.project
  location = var.location
  cluster  = module.gke_cluster.name

  initial_node_count = "1"

  autoscaling {
    min_node_count = "1"
    max_node_count = "5"
  }

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  node_config {
    image_type   = "COS"
    machine_type = "n1-standard-1"

    labels = {
      private-pools-example = "true"
    }

    tags = [
      "private-pool-example",
    ]

    disk_size_gb = "30"
    disk_type    = "pd-standard"
    preemptible  = false

    service_account = module.gke_service_account.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# VPC Network 

module "vpc_network" {
  source = "./modules/my-vpc-network"

  name_prefix = "${var.cluster_name}-network-${random_string.suffix.result}"
  project     = var.project
  region      = var.region

  cidr_block           = var.vpc_cidr_block
  secondary_cidr_block = var.vpc_secondary_cidr_block
}

# GKE SA

module "gke_service_account" {
  source = "./modules/my-gke-service-account"

  name        = var.cluster_service_account_name
  project     = var.project
  description = var.cluster_service_account_description
}

# Configire kubectl

resource "null_resource" "configure_kubectl" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${module.gke_cluster.name} --region ${var.region} --project ${var.project}"
    environment = {
      KUBECONFIG = var.kubectl_config_path != "" ? var.kubectl_config_path : ""
    }
  }
  depends_on = [google_container_node_pool.node_pool]
}

# Tiller SA

resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = local.tiller_namespace
  }
}

# Role Binding

resource "kubernetes_cluster_role_binding" "user" {
  metadata {
    name = "admin-user"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "User"
    name      = data.google_client_openid_userinfo.terraform_user.email
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    api_group = ""

    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tiller.metadata[0].name
    namespace = local.tiller_namespace
  }

  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }
}

# Genrate tls cert for use with tiler

resource "null_resource" "tiller_tls_certs" {
  provisioner "local-exec" {
    command = <<-EOF
      <Command to genrate ca cert> tls gen --ca --namespace kube-system --secret-name ${local.tls_ca_secret_name} --secret-label gruntwork.io/tiller-namespace=${local.tiller_namespace} --secret-label gruntwork.io/tiller-credentials=true --secret-label gruntwork.io/tiller-credentials-type=ca --tls-subject-json '${jsonencode(var.tls_subject)}' ${local.tls_algorithm_config} ${local.kubectl_auth_config}
      <Command to genrate tls cert> tls gen --namespace ${local.tiller_namespace} --ca-secret-name ${local.tls_ca_secret_name} --ca-namespace kube-system --secret-name ${local.tls_secret_name} --secret-label gruntwork.io/tiller-namespace=${local.tiller_namespace} --secret-label gruntwork.io/tiller-credentials=true --secret-label gruntwork.io/tiller-credentials-type=server --tls-subject-json '${jsonencode(var.tls_subject)}' ${local.tls_algorithm_config} ${local.kubectl_auth_config}
    EOF

    environment = {
      KUBECTL_SERVER_ENDPOINT = data.template_file.gke_host_endpoint.rendered
      KUBECTL_CA_DATA         = base64encode(data.template_file.cluster_ca_certificate.rendered)
      KUBECTL_TOKEN           = data.template_file.access_token.rendered
    }
  }
}

module "trigger-gcr" {
  source     = "./modules/my-codebuild-gcr"
  # Name of the repositroy where your Dockerfile Exists which you want ot build in my case it's same repo.
  repository = "terraform-k8s-test-repo"

  triggers = [
    {
      branch = "master"
    },
    {
      branch = "dev"
      tag_type = "$SHORT_SHA"
    },
  ]
}

## Now here we can either create a module that deploys tiler on kubernetes or deploy tiler 
## directly. But Due to time constaint wasn't able to complete that.

# Now we have Kubernetes on GCP with tiler(once deployed) Just need do deployment using Helm.