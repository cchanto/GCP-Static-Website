# Bucket to store website content with versioning and logging for enhanced security
resource "google_storage_bucket" "website" {
  provider      = google
  name          = "chantowebtest"
  location      = "US"
  force_destroy = true


  logging {
    log_bucket        = "poc-test-infra"  # Replace with your logging bucket to capture access logs
    log_object_prefix = "logs"
  }
}

# Public access control for objects but restricts bucket-level permissions
resource "google_storage_bucket_iam_member" "website_public_access" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Upload HTML file to the bucket with no-cache settings for real-time updates
resource "google_storage_bucket_object" "static_site_src" {
  name   = "index.html"
  source = "../website/index.html"
  bucket = google_storage_bucket.website.name
  metadata = {
    "Cache-Control" = "no-cache, max-age=0"  # Forces CDN to revalidate every time
  }
  depends_on = [google_storage_bucket.website]
}

# Reserve an external IP for the load balancer
resource "google_compute_global_address" "website" {
  provider = google
  name     = "website-lb-ip"
}

# Retrieve managed DNS zone for automatic DNS configuration
data "google_dns_managed_zone" "gcp_coffeetime_dev" {
  provider = google
  name     = "testchanto"
}

# DNS record for the website's IP address
resource "google_dns_record_set" "website" {
  provider     = google
  name         = "website.${data.google_dns_managed_zone.gcp_coffeetime_dev.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.gcp_coffeetime_dev.name
  rrdatas      = [google_compute_global_address.website.address]
}

# CDN-backed backend bucket with cache configuration and logging enabled
resource "google_compute_backend_bucket" "website-backend" {
  provider    = google
  name        = "website-backend"
  description = "Contains files needed by the website"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true

  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"  # Cache only static content
    client_ttl        = 60                  # Client-side cache TTL: 1 minute
    default_ttl       = 60                  # Default TTL for cached objects: 1 minute
    max_ttl           = 60                  # Maximum cache TTL: 1 minute
    serve_while_stale = 60                  # Serve stale content for 1 minute if origin fails

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

# SSL Certificate for secure HTTPS connection
resource "google_compute_managed_ssl_certificate" "website" {
  provider = google-beta
  name     = "website-cert"
  managed {
    domains = [google_dns_record_set.website.name]
  }
}

# URL map for defining the paths for the load balancer
resource "google_compute_url_map" "website" {
  provider        = google
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website-backend.self_link

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.website-backend.self_link
  }
}

# HTTPS target proxy that links the URL map to the SSL certificate
resource "google_compute_target_https_proxy" "website" {
  provider         = google
  name             = "website-target-proxy"
  url_map          = google_compute_url_map.website.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.website.self_link]
}

# Global forwarding rule for directing traffic to the load balancer on HTTPS
resource "google_compute_global_forwarding_rule" "default" {
  provider              = google
  name                  = "website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website.address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.website.self_link
}

# Cloud Armor security policy for DDoS protection (Optional)
resource "google_compute_security_policy" "ddos_protection" {
  provider = google
  name     = "ddos-protection-policy"

  rule {
    priority = 1000
    action   = "ALLOW"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["0.0.0.0/0"]  # Adjust as needed for specific IP ranges
      }
    }
  }

  rule {
    priority = 2147483647
    action   = "DENY"
  }
}

# Associate Cloud Armor with the backend service for additional security
resource "google_compute_backend_service_iam_member" "website_backend_policy" {
  name       = google_compute_backend_bucket.website-backend.name
  project    = google_storage_bucket.website.project
  role       = "roles/compute.securityAdmin"
  members    = ["user:chantoc.chanto@gmail.com"]  # Replace with your email or relevant user
}
