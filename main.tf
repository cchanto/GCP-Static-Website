
variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default = "poc-test-infra"
}

terraform {
  
  backend "gcs" {
    bucket  = "poc-test-infra"
    prefix  = "poc"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.8.0"
    }
  }
}
module "storage" {
  source          = "./modules/storage"
  bucket_name     = "chantowebtest1"
  bucket_location = "US"
  project_id      = var.project_id // Pass the project ID
}

module "networking" {
  source              = "./modules/networking"
  global_address_name = "website2-lb-ip"
  dns_zone_name       = "testchanto"
  project_id          = var.project_id // Pass the project ID
}

module "load_balancer" {
  source              = "./modules/load_balancer"
  backend_bucket_name = "website1-backend"
  bucket_name         = module.storage.bucket_name
  url_map_name        = "website1-url-map"
  target_proxy_name   = "website1-target-proxy"
  forwarding_rule_name = "website1-forwarding-rule"
  ssl_certificate     = module.ssl_certificate.ssl_certificate_self_link
  global_address      = module.networking.global_ip_address
  project_id          = var.project_id // Pass the project ID
}


module "ssl_certificate" {
  source               = "./modules/ssl_certificate"
  ssl_certificate_name = "website-cert"
  domain_name          = "testchanto.com" // Replace with your actual domain
  project_id          = var.project_id // Pass the project ID
}
