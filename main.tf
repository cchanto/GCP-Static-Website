terraform {
  backend "gcs" {
    bucket  = "inframodules"
    prefix  = "poc"
  }
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.8.0"
    }
  }
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "poc-test-infra"
}

module "storage" {
  source          = "./modules/storage"
  bucket_name     = "chantowebtestmodules"
  bucket_location = "US"
  project_id      = var.project_id  // Pass the project ID
}

module "networking" {
  source              = "./modules/networking"
  global_address_name = "websitepoc1-lb-ip"
  dns_zone_name       = "testchanto"
  project_id          = var.project_id  // Pass the project ID
}

module "ssl_certificate" {
  source               = "./modules/ssl_certificate"
  ssl_certificate_name = "websitepoc-cert"
  domain_name          = "testchantopoc.com"  // Replace with your actual domain
  project_id          = var.project_id  // Pass the project ID
}

module "load_balancer" {
  source                = "./modules/load_balancer"
  backend_bucket_name   = "websitepoc-backend"
  bucket_name           = module.storage.bucket_name
  url_map_name          = "websitepoc-url-map"  // Should match the variable defined in the load balancer module
  target_proxy_name     = "websitepoc-target-proxy"  // Ensure this matches the variable in variables.tf
  forwarding_rule_name   = "websitepoc-forwarding-rule"
  ssl_certificate       = module.ssl_certificate.ssl_certificate_self_link
  global_address        = module.networking.global_ip_address
  project_id            = var.project_id  // Pass the project ID
  websitepoc-target-proxy = var.target_proxy_name
}



variable "target_proxy_name" {
  description = "The name of the target proxy"
  type        = string
  default     = "websitepoc-target-proxy"  # Provide a default value or set it in the root module's input variables
}
