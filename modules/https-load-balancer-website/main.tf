locals {
  website_domain_name_dashed = replace(var.website_domain_name, ".", "-")
}

# Allocate a Global IP Address for Load Balancer
resource "google_compute_global_address" "static_ip" {
  name    = "${local.website_domain_name_dashed}-ip"
  project = var.project
}

# Backend Bucket with CDN Enabled
resource "google_compute_backend_bucket" "static" {
  provider    = google-beta
  project     = var.project
  name        = "${local.website_domain_name_dashed}-bucket"
  bucket_name = module.site_bucket.website_bucket_name
  enable_cdn  = var.enable_cdn

  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"  # Caches only static content
    client_ttl        = 60                  # Cache in client browsers for 1 minute
    default_ttl       = 60                  # Default TTL of 1 minute for cached content
    max_ttl           = 300                 # Maximum TTL of 5 minutes
    serve_while_stale = 60                  # Serve stale content for 1 minute if origin fails
  }
}

# URL Map for Load Balancer to Route Requests to Backend Bucket
resource "google_compute_url_map" "url_map" {
  provider        = google-beta
  project         = var.project
  name            = "${local.website_domain_name_dashed}-url-map"
  default_service = google_compute_backend_bucket.static.self_link
}

# HTTPS Target Proxy
resource "google_compute_target_https_proxy" "https_proxy" {
  provider         = google-beta
  project          = var.project
  name             = "${local.website_domain_name_dashed}-https-proxy"
  url_map          = google_compute_url_map.url_map.self_link
  ssl_certificates = [var.ssl_certificate]  # SSL certificate variable
}

# HTTPS Forwarding Rule
resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  provider    = google-beta
  project     = var.project
  name        = "${local.website_domain_name_dashed}-https-forwarding-rule"
  target      = google_compute_target_https_proxy.https_proxy.self_link
  ip_address  = google_compute_global_address.static_ip.address
  port_range  = "443"
}

# DNS Record for Static Site (CNAME or A Record based on requirements)
resource "google_dns_record_set" "dns_record" {
  count        = var.create_dns_entry ? 1 : 0
  name         = "${var.website_domain_name}."
  managed_zone = var.dns_managed_zone_name
  type         = var.enable_ssl ? "A" : "CNAME"
  ttl          = var.dns_record_ttl
  rrdatas      = var.enable_ssl ? [google_compute_global_address.static_ip.address] : ["c.storage.googleapis.com"]
}

# Site Bucket Module for GCS Hosting
module "site_bucket" {
  source                      = "../cloud-storage-static-website"
  project                     = var.project
  website_domain_name         = local.website_domain_name_dashed
  website_acls                = var.website_acls
  website_location            = var.website_location
  website_storage_class       = var.website_storage_class
  force_destroy_website       = var.force_destroy_website
  index_page                  = var.index_page
  not_found_page              = var.not_found_page
  enable_versioning           = var.enable_versioning
  access_log_prefix           = var.access_log_prefix
  access_logs_expiration_time_in_days = var.access_logs_expiration_time_in_days
  force_destroy_access_logs_bucket    = var.force_destroy_access_logs_bucket
  website_kms_key_name               = var.website_kms_key_name
  access_logs_kms_key_name           = var.access_logs_kms_key_name
  enable_cors                        = var.enable_cors
  cors_extra_headers                 = var.cors_extra_headers
  cors_max_age_seconds               = var.cors_max_age_seconds
  cors_methods                       = var.cors_methods
  cors_origins                       = var.cors_origins
  create_dns_entry                   = false
  custom_labels                      = var.custom_labels
}
