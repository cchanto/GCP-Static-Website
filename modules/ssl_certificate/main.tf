
        resource "google_compute_managed_ssl_certificate" "website" {
          provider = google-beta
          name     = var.ssl_certificate_name
          managed {
            domains = [var.domain_name]
          }
        }
        