
        resource "google_compute_backend_bucket" "website-backend" {
          provider    = google
          name        = var.backend_bucket_name
          bucket_name = var.bucket_name
          enable_cdn  = true
        }

        resource "google_compute_url_map" "website" {
          provider        = google
          name            = var.url_map_name
          default_service = google_compute_backend_bucket.website-backend.self_link

          path_matcher {
            name            = "allpaths"
            default_service = google_compute_backend_bucket.website-backend.self_link
          }
        }

        resource "google_compute_target_https_proxy" "website" {
          provider         = google
          name             = var.target_proxy_name
          url_map          = google_compute_url_map.website.self_link
          ssl_certificates = [var.ssl_certificate]
        }

        resource "google_compute_global_forwarding_rule" "default" {
          provider              = google
          name                  = var.forwarding_rule_name
          load_balancing_scheme = "EXTERNAL"
          ip_address            = var.global_address
          ip_protocol           = "TCP"
          port_range            = "443"
          target                = google_compute_target_https_proxy.website.self_link
        }
        