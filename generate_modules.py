import os

# Module: ssl_certificate
modules['ssl_certificate']['outputs.tf'] = '''

        output "ssl_certificate_self_link" {
          value = google_compute_managed_ssl_certificate.website.self_link
        }
        
'''
modules['ssl_certificate']['main.tf'] = '''

        resource "google_compute_managed_ssl_certificate" "website" {
          provider = google-beta
          name     = var.ssl_certificate_name
          managed {
            domains = [var.domain_name]
          }
          project = var.project_id // Ensure project is set
        }
        
'''
modules['ssl_certificate']['variables.tf'] = '''

        variable "ssl_certificate_name" {
          description = "Name of the managed SSL certificate"
          type        = string
        }

        variable "domain_name" {
          description = "Domain name for the SSL certificate"
          type        = string
        }

        variable "project_id" {
          description = "The GCP project ID"
          type        = string
        }
        
'''

# Module: load_balancer
modules['load_balancer']['outputs.tf'] = '''

output "forwarding_rule" {
  value = google_compute_global_forwarding_rule.default.name
}
        
'''
modules['load_balancer']['main.tf'] = '''
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
  name     = "websitelbip"  # Should be a valid name, not an IP
  project  = var.project_id  # Ensure project is set
}

# Retrieve the managed DNS zone
data "google_dns_managed_zone" "gcp_dev" {
  provider = google
  project  = var.project_id  # Ensure project is set
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
  project      = var.project_id  # Ensure project is set
}

# Backend bucket with CDN enabled and cache configuration
resource "google_compute_backend_bucket" "website-backend" {
  provider    = google
  project     = var.project_id  # Ensure project is set
  name        = "websitepoc-backend"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true
}

# Create HTTPS certificate
resource "google_compute_managed_ssl_certificate" "website" {
  provider = google-beta
  project  = var.project_id  # Ensure project is set
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
  # path_matcher {
  #   name            = "allpaths"  # Define a path matcher
  #   default_service = google_compute_backend_bucket.website-backend.self_link
  #   path_rule {
  #     paths   = ["/*"]  # Match all paths
  #     service = google_compute_backend_bucket.website-backend.self_link  # Specify backend service
  #   }
  # }
}
# HTTPS Target Proxy
resource "google_compute_target_https_proxy" "website" {
  provider         = google
  name             = var.target_proxy_name  # Use the passed variable
  url_map          = google_compute_url_map.website.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.website.self_link]
  project          = var.project_id  # Ensure project is set
}

# HTTPS Forwarding Rule
resource "google_compute_global_forwarding_rule" "default" {
  provider              = google
  project               = var.project_id  # Ensure project is set
  name                  = "websitepoc-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website.address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.website.self_link  # Correct reference to HTTPS target proxy
}

'''
modules['load_balancer']['variables.tf'] = '''

variable "backend_bucket_name" {
  description = "Name of the backend bucket for the load balancer"
  type        = string
  default     = "websitepoc-backend"
}

variable "bucket_name" {
  description = "GCS bucket name for the website content"
  type        = string
}

variable "url_map_name" {
  description = "Name for the URL map"
  type        = string
  default     = "websitepoc-url-map"
}

variable "target_proxy_name" {
  description = "Name of the HTTPS target proxy"
  type        = string
  default     = "websitepoc-target-proxy"
}

variable "forwarding_rule_name" {
  description = "Name of the global forwarding rule"
  type        = string
  default     = "websitepoc-forwarding-rule"
}

variable "ssl_certificate" {
  description = "SSL Certificate to be used"
  type        = string
}

variable "global_address" {
  description = "Name for the reserved global IP address"
  type        = string
  default     = "websitepoc-lb-ip"  # Ensure this is a valid name
}


variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default = "poc-test-infra"
}
        

variable "websitepoc-cert" {
  description = "HTTPS cert name"
  default = "websitep11oc-cert"
}

variable "websitepoc-target-proxy" {
   type = string
}

variable "website-url-map" {
  type        = string
  default = "websitep11oc"
}


'''

# Module: networking
modules['networking']['outputs.tf'] = '''

        output "dns_record" {
          value = google_dns_record_set.website.name
        }

        output "global_ip_address" {
          value = google_compute_global_address.website.address
        }
        
'''
modules['networking']['main.tf'] = '''
resource "google_compute_global_address" "website" {
  provider = google
  name     = var.global_address_name
  project  = var.project_id // Ensure project is set
}

data "google_dns_managed_zone" "gcp_dev" {
  provider = google
  name     = var.dns_zone_name
  project  = var.project_id // Ensure project is set
}

resource "google_dns_record_set" "website" {
  provider     = google
  name         = "website.${data.google_dns_managed_zone.gcp_dev.dns_name}"
  type         = "A"
  ttl          = 30
  managed_zone = data.google_dns_managed_zone.gcp_dev.name
  rrdatas      = [google_compute_global_address.website.address]
  project      = var.project_id // Ensure project is set
}

'''
modules['networking']['variables.tf'] = '''

        variable "global_address_name" {
          description = "Name for the reserved global IP address"
          type        = string
          default     = "website2-lb-ip"
        }

        variable "dns_zone_name" {
          description = "DNS Zone name"
          type        = string
        }

        variable "project_id" {
          description = "The GCP project ID"
          type        = string
        }
        
'''

# Module: website

# Module: storage
modules['storage']['outputs.tf'] = '''

        output "bucket_name" {
          value = google_storage_bucket.website.name
        }
        
'''
modules['storage']['main.tf'] = '''
resource "google_storage_bucket" "website" {
  provider      = google
  name          = var.bucket_name
  location      = var.bucket_location
  force_destroy = true
  project       = var.project_id // Ensure project is set

  versioning {
    enabled = false
  }
}

resource "google_storage_object_access_control" "public_rule" {
  object = google_storage_bucket_object.static_site_src.output_name
  bucket = google_storage_bucket.website.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket_object" "static_site_src" {
  name   = "index.html"
  source = "modules/website/index.html"  # Ensure this file exists
  bucket = google_storage_bucket.website.name
  metadata = {
    "Cache-Control" = "no-cache, max-age=0"
  }
  depends_on = [google_storage_bucket.website]
}

'''
modules['storage']['variables.tf'] = '''

        variable "bucket_name" {
          description = "Name of the GCS bucket"
          type        = string
        }

        variable "bucket_location" {
          description = "Location of the GCS bucket"
          type        = string
          default     = "US"
        }

        variable "project_id" {
          description = "The GCP project ID"
          type        = string
        }
        
'''

modules = {
    'ssl_certificate': {
        'outputs.tf': modules['ssl_certificate']['outputs.tf'],
        'main.tf': modules['ssl_certificate']['main.tf'],
        'variables.tf': modules['ssl_certificate']['variables.tf'],
    },
    'load_balancer': {
        'outputs.tf': modules['load_balancer']['outputs.tf'],
        'main.tf': modules['load_balancer']['main.tf'],
        'variables.tf': modules['load_balancer']['variables.tf'],
    },
    'networking': {
        'outputs.tf': modules['networking']['outputs.tf'],
        'main.tf': modules['networking']['main.tf'],
        'variables.tf': modules['networking']['variables.tf'],
    },
    'website': {
    },
    'storage': {
        'outputs.tf': modules['storage']['outputs.tf'],
        'main.tf': modules['storage']['main.tf'],
        'variables.tf': modules['storage']['variables.tf'],
    },
}
