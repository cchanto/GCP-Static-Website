# Define the storage bucket
resource "google_storage_bucket" "website" {
  provider      = google
  project       = var.project_id // Ensure project is set
  name          = "chantowebtest"
  location      = "US"
  force_destroy = true

  versioning {
    enabled = false
  }

  lifecycle {
    prevent_destroy = false  # Prevent accidental deletion
  }
}

# Make new objects public
resource "google_storage_object_access_control" "public_rule" {
  object = google_storage_bucket_object.static_site_src.output_name
  bucket = google_storage_bucket.website.name
  role   = "READER"
  entity = "allUsers"
}

# Upload the HTML file to the bucket with Cache-Control header
resource "google_storage_bucket_object" "static_site_src" {
  name   = "index.html"
  source = "modules/website/index.html"  # Ensure this file exists
  bucket = google_storage_bucket.website.name

  metadata = {
    "Cache-Control" = "no-cache, max-age=0"  # Forces CDN to revalidate every time
  }
  depends_on = [google_storage_bucket.website]
}

# Reserve an external IP
resource "google_compute_global_address" "website" {
  provider = google
  name     = "websitelbip"  // Should be a valid name, not an IP
  project  = var.project_id      // Ensure project is set
}

# Retrieve the managed DNS zone
data "google_dns_managed_zone" "gcp_dev" {
  provider = google
  project  = var.project_id // Ensure project is set
  name     = "testchanto"  # Ensure this DNS zone exists
}

# Add the IP to the DNS record
resource "google_dns_record_set" "website" {
  provider     = google
  name         = "websitepoc.${data.google_dns_managed_zone.gcp_dev.dns_name}"
  type         = "A"
  ttl          = 30
  managed_zone = data.google_dns_managed_zone.gcp_dev.name
  rrdatas      = [google_compute_global_address.website.address]
  project      = var.project_id // Ensure project is set
}

# Backend bucket with CDN enabled and cache configuration
resource "google_compute_backend_bucket" "website-backend" {
  provider    = google
  project     = var.project_id // Ensure project is set
  name        = "websitepoc-backend"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true
}

# Create HTTPS certificate
resource "google_compute_managed_ssl_certificate" "website" {
  provider = google-beta
  project  = var.project_id // Ensure project is set
  name     = var.websitepoc-cert
  managed {
    domains = [google_dns_record_set.website.name]
  }
}
# Define the URL map for the load balancer
resource "google_compute_url_map" "website" {
  provider        = google
  project         = var.project_id  # Ensure project is set
  name            = "websitepoc-url-map"
  default_service = google_compute_backend_bucket.website-backend.self_link  # Set default service

  path_matcher {
    name            = "allpaths"  # Define a path matcher
    default_service = google_compute_backend_bucket.website-backend.self_link

    path_rule {
      paths   = ["/*"]  # Match all paths
      service = google_compute_backend_bucket.website-backend.self_link  # Specify backend service
    }
  }
}


# Define the URL map for the load balancer
resource "google_compute_url_map" "website1" {
  provider        = google
  project         = var.project_id  # Ensure project is set
  name            = var.website-url-map
  default_service = google_compute_backend_bucket.website-backend.self_link  # Set default service

  path_matcher {
    name            = "allpaths"  # Define a path matcher
    default_service = google_compute_backend_bucket.website-backend.self_link  # Set default backend service

    path_rule {
      paths   = ["/*"]  # Match all paths
      service = google_compute_backend_bucket.website-backend.self_link  # Specify backend service
    }
  }
}


resource "google_compute_target_https_proxy" "website" {
  provider         = google
  name             = var.target_proxy_name  // Use the passed variable
  url_map          = google_compute_url_map.website.self_link
  ssl_certificates = [var.ssl_certificate]
  project          = var.project_id // Ensure project is set
}


# HTTPS Forwarding Rule
resource "google_compute_global_forwarding_rule" "default" {
  provider              = google
  project               = var.project_id  # Ensure project is set
  name                  = "website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website.address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.website.self_link  # Reference the HTTPS target proxy
}
