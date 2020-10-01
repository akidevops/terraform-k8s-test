provider "google" {
  version = "~> 2.9.0"
  project = var.project
  region  = var.region
}

provider "kubernetes" {
  version                = "~> 1.7.0"
  load_config_file       = false
  host                   = data.template_file.gke_host_endpoint.rendered
  token                  = data.template_file.access_token.rendered
  cluster_ca_certificate = data.template_file.cluster_ca_certificate.rendered
}

provider "helm" {
  install_tiller = true
  enable_tls     = true
  kubernetes {
    host                   = data.template_file.gke_host_endpoint.rendered
    token                  = data.template_file.access_token.rendered
    cluster_ca_certificate = data.template_file.cluster_ca_certificate.rendered
  }
}

data "google_client_config" "client" {}

data "google_client_openid_userinfo" "terraform_user" {}
