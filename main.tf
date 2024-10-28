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



provider "google" {
  project = var.project
  region  = "us-central1"
}




module "static_site" {
  source = "./modules/cloud-storage-static-website"

  project                       = var.project
  website_domain_name           = var.website_domain_name
  website_location              = var.website_location
  force_destroy_access_logs_bucket = var.force_destroy_access_logs_bucket
  force_destroy_website         = var.force_destroy_website
  create_dns_entry              = var.create_dns_entry
  dns_record_ttl                = var.dns_record_ttl
  dns_managed_zone_name         = var.dns_managed_zone_name
  enable_versioning             = var.enable_versioning
  index_page                    = var.index_page
  not_found_page                = var.not_found_page
}

# Read dynamically generated content from index.html with Cache-Control headers
resource "google_storage_bucket_object" "index" {
  name    = var.index_page
  content = file("index.html")  # Reads content from the generated index.html file
  bucket  = module.static_site.website_bucket_name
  metadata = {
    "Cache-Control" = "no-cache, max-age=0"
  }
}

# Existing not_found bucket object with Cache-Control headers
resource "google_storage_bucket_object" "not_found" {
  name    = var.not_found_page
  content = "Uh oh"
  bucket  = module.static_site.website_bucket_name
  metadata = {
    "Cache-Control" = "no-cache, max-age=0"
  }
}


# ACL for index object to make it publicly readable
resource "google_storage_object_acl" "index_acl" {
  bucket      = module.static_site.website_bucket_name
  object      = google_storage_bucket_object.index.name
  role_entity = ["READER:allUsers"]
}

# ACL for not found page to make it publicly readable
resource "google_storage_object_acl" "not_found_acl" {
  bucket      = module.static_site.website_bucket_name
  object      = google_storage_bucket_object.not_found.name
  role_entity = ["READER:allUsers"]
}

# IAM Binding to make the bucket publicly accessible
resource "google_storage_bucket_iam_binding" "public_access" {
  bucket = module.static_site.website_bucket_name
  role   = "roles/storage.objectViewer"
  members = ["allUsers"]
}
