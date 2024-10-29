resource "google_storage_bucket" "website" {
  provider      = google
  name          = "chantowebtest"
  location      = "US"
  force_destroy = true

  versioning {
    enabled = false
  }

  lifecycle {
    prevent_destroy = true  # Prevent accidental deletion
  }
}

variable "project_id" {
     default     = "poc-test-infra"
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
  source = "../website/index.html"  # Ensure this file exists
  bucket = google_storage_bucket.website.name

  metadata = {
    "Cache-Control" = "no-cache, max-age=0"  # Forces CDN to revalidate every time
  }
  depends_on = [google_storage_bucket.website]
}

# Reserve an external IP
resource "google_compute_global_address" "website" {
  provider = google
  name     = "website-lb-ip"
  project  =  poc-test-infra // Ensure project is set
}

# Retrieve the managed DNS zone
data "google_dns_managed_zone" "gcp_coffeetime_dev" {
  provider = google
  name     = "testchanto"  # Ensure this DNS zone exists
  project  = poc-test-infra // Ensure project is set
}

# Add the IP to the DNS record
resource "google_dns_record_set" "website" {
  provider     = google
  name         = "website.${data.google_dns_managed_zone.gcp_coffeetime_dev.dns_name}"
  type         = "A"
  ttl          = 30
  managed_zone = data.google_dns_managed_zone.gcp_coffeetime_dev.name
  rrdatas      = [google_compute_global_address.website.address]
  project      = poc-test-infra // Ensure project is set
}

# Backend bucket with CDN enabled and cache configuration
resource "google_compute_backend_bucket" "website-backend" {
  provider    = google
  name        = "website-backend"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true
  project     = poc-test-infra // Ensure project is set

  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"   # Cache only static content
    client_ttl        = 60                   # Client-side cache TTL: 1 minute
    default_ttl       = 60                   # Default TTL for cached objects: 1 minute
    max_ttl           = 60                   # Maximum cache TTL for objects: 1 minute
    serve_while_stale = 60                   # Serve stale content for 1 day if origin fails

    negative_caching = true
    negative_caching_policy {
      code = 404
      ttl  = 30  # Cache 404 responses for 30 seconds
    }
    negative_caching_policy {
      code = 410
      ttl  = 30  # Cache 410 responses for 30 seconds
    }
  }
}

# Create HTTPS certificate
resource "google_compute_managed_ssl_certificate" "website" {
  provider = google-beta
  name     = "website-cert"
  managed {
    domains = [google_dns_record_set.website.name]
  }
}

# Define the URL map for the load balancer
resource "google_compute_url_map" "website" {
  provider        = google
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website-backend.self_link

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.website-backend.self_link

    path_rule {
      paths   = ["/*"]  # Match all paths
      service = google_compute_backend_bucket.website-backend.self_link  # Specify backend service
    }
  }
}

# HTTPS Target Proxy
resource "google_compute_target_https_proxy" "website" {
  provider         = google
  name             = "website-target-proxy"
  url_map          = google_compute_url_map.website.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.website.self_link]
  project          = poc-test-infra // Ensure project is set
}

# HTTPS Forwarding Rule
resource "google_compute_global_forwarding_rule" "default" {
  provider              = google
  name                  = "website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website.address
  ip_protocol           = "TCP"  # Updated to TCP for compatibility
  port_range            = "443"
  target                = google_compute_target_https_proxy.website.self_link
  project               = poc-test-infra // Ensure project is set
}

# Google Cloud Armor security policy
resource "google_compute_security_policy" "web_security_policy" {
  provider = google
  name     = "web-security-policy"
}

# Security policy rule to deny traffic from specific IPs
resource "google_compute_security_policy_rule" "deny_rule" {
  provider        = google
  security_policy = google_compute_security_policy.web_security_policy.id
  priority        = 1000
  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["192.0.2.0/24"]  # Example IPs to block
    }
  }
  action = "deny-403"  # Deny access for specific IPs
}

# Apply security policy to backend service
resource "google_compute_backend_service" "website_backend" {
  provider = google
  name     = "website-backend-service"
  backend {
    group = google_compute_backend_bucket.website-backend.self_link
  }
  security_policy = google_compute_security_policy.web_security_policy.id
}
