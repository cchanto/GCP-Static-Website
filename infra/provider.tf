# GCP provider

provider "google" {
  #credentials  = file(var.gcp_svc_key)
  project      = var.gcp_project
  region       = var.gcp_region
}

# GCP beta provider
provider "google-beta" {
  #credentials  = file(var.gcp_svc_key)
  project      = var.gcp_project
  region       = var.gcp_region
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




