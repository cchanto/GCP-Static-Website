

locals {
  website_domain_name_dashed = replace(var.website_domain_name, ".", "-")
}

# Load Balancer Module
module "load_balancer" {
  source                = "gruntwork-io/load-balancer/google"
  name                  = local.website_domain_name_dashed
  project               = var.project
  url_map               = google_compute_url_map.urlmap.self_link
  create_dns_entries    = var.create_dns_entry
  custom_domain_names   = [var.website_domain_name]
  dns_managed_zone_name = var.dns_managed_zone_name
  dns_record_ttl        = var.dns_record_ttl
  enable_http           = var.enable_http
  enable_ssl            = var.enable_ssl
  ssl_certificates      = [var.ssl_certificate]
  custom_labels         = var.custom_labels
}

# # URL Map for Load Balancer
# resource "google_compute_url_map" "urlmap" {
#   provider    = google-beta
#   project     = var.project
#   name        = "${local.website_domain_name_dashed}-url-map"
#   description = "URL map for ${local.website_domain_name_dashed}"
#   default_service = google_compute_backend_bucket.static.self_link
# }

resource "google_compute_backend_bucket" "static" {
  provider    = google-beta
  project     = var.project
  name        = "${local.website_domain_name_dashed}-bucket"
  bucket_name = module.site_bucket.website_bucket_name
  enable_cdn  = var.enable_cdn
  
  cdn_policy {
    cache_mode             = "CACHE_ALL_STATIC"  # Caches only static content
    client_ttl             = 60                  # Cache in client browsers for 1 minute
    default_ttl            = 60                  # Default TTL of 1 minute for cached content
    max_ttl                = 300                 # Maximum TTL of 5 minutes
    serve_while_stale      = 60                  # Serve stale content for 1 minute if origin fails
  }
}



# Backend Bucket with CDN Enabled
resource "google_compute_backend_bucket" "static" {
  provider    = google-beta
  project     = var.project
  name        = "${local.website_domain_name_dashed}-bucket"
  bucket_name = module.site_bucket.website_bucket_name
  enable_cdn  = var.enable_cdn
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

# # DNS Record - CNAME for Static Site
# resource "google_dns_record_set" "cname_record" {
#   count        = var.enable_ssl && var.create_dns_entry ? 1 : 0
#   name         = "${var.website_domain_name}."
#   managed_zone = var.dns_managed_zone_name
#   type         = "CNAME"
#   ttl          = var.dns_record_ttl
#   rrdatas      = [module.site_bucket.website_url] # Point to the GCS bucket URL
# }

# # DNS Record - A Record for IP if Load Balancer is Used
# resource "google_dns_record_set" "a_record" {
#   count        = var.enable_http && var.create_dns_entry ? 1 : 0
#   name         = "${var.website_domain_name}."
#   managed_zone = var.dns_managed_zone_name
#   type         = "A"
#   ttl          = var.dns_record_ttl
#   rrdatas      = [module.load_balancer.load_balancer_ip] # Point to Load Balancer IP
# }