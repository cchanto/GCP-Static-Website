import os

# Define module content for each file type
modules = {
    "storage": {
        "main.tf": """
        resource "google_storage_bucket" "website" {
          provider      = google
          name          = var.bucket_name
          location      = var.bucket_location
          force_destroy = true

          versioning {
            enabled = true
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
          source = "../website/index.html"
          bucket = google_storage_bucket.website.name
          metadata = {
            "Cache-Control" = "no-cache, max-age=0"
          }
          depends_on = [google_storage_bucket.website]
        }
        """,
        "variables.tf": """
        variable "bucket_name" {
          description = "Name of the GCS bucket"
          type        = string
        }

        variable "bucket_location" {
          description = "Location of the GCS bucket"
          type        = string
          default     = "US"
        }
        """,
        "outputs.tf": """
        output "bucket_name" {
          value = google_storage_bucket.website.name
        }
        """
    },
    "networking": {
        "main.tf": """
        resource "google_compute_global_address" "website" {
          provider = google
          name     = var.global_address_name
        }

        data "google_dns_managed_zone" "gcp_coffeetime_dev" {
          provider = google
          name     = var.dns_zone_name
        }

        resource "google_dns_record_set" "website" {
          provider     = google
          name         = "website.${data.google_dns_managed_zone.gcp_coffeetime_dev.dns_name}"
          type         = "A"
          ttl          = 30
          managed_zone = data.google_dns_managed_zone.gcp_coffeetime_dev.name
          rrdatas      = [google_compute_global_address.website.address]
        }
        """,
        "variables.tf": """
        variable "global_address_name" {
          description = "Name for the reserved global IP address"
          type        = string
          default     = "website-lb-ip"
        }

        variable "dns_zone_name" {
          description = "DNS Zone name"
          type        = string
        }
        """,
        "outputs.tf": """
        output "dns_record" {
          value = google_dns_record_set.website.name
        }

        output "global_ip_address" {
          value = google_compute_global_address.website.address
        }
        """
    },
    "load_balancer": {
        "main.tf": """
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
        """,
        "variables.tf": """
        variable "backend_bucket_name" {
          description = "Name of the backend bucket for the load balancer"
          type        = string
          default     = "website-backend"
        }

        variable "bucket_name" {
          description = "GCS bucket name for the website content"
          type        = string
        }

        variable "url_map_name" {
          description = "Name for the URL map"
          type        = string
          default     = "website-url-map"
        }

        variable "target_proxy_name" {
          description = "Name of the HTTPS target proxy"
          type        = string
          default     = "website-target-proxy"
        }

        variable "forwarding_rule_name" {
          description = "Name of the global forwarding rule"
          type        = string
          default     = "website-forwarding-rule"
        }

        variable "ssl_certificate" {
          description = "SSL Certificate to be used"
          type        = string
        }

        variable "global_address" {
          description = "Global IP address for the load balancer"
          type        = string
        }
        """,
        "outputs.tf": """
        output "forwarding_rule" {
          value = google_compute_global_forwarding_rule.default.name
        }
        """
    },
    "ssl_certificate": {
        "main.tf": """
        resource "google_compute_managed_ssl_certificate" "website" {
          provider = google-beta
          name     = var.ssl_certificate_name
          managed {
            domains = [var.domain_name]
          }
        }
        """,
        "variables.tf": """
        variable "ssl_certificate_name" {
          description = "Name of the managed SSL certificate"
          type        = string
        }

        variable "domain_name" {
          description = "Domain name for the SSL certificate"
          type        = string
        }
        """,
        "outputs.tf": """
        output "ssl_certificate_self_link" {
          value = google_compute_managed_ssl_certificate.website.self_link
        }
        """
    }
}

# Base directory setup for modules
module_base_dir = "./modules"
os.makedirs(module_base_dir, exist_ok=True)

# Create module directories and populate files
for module_name, files in modules.items():
    module_path = os.path.join(module_base_dir, module_name)
    os.makedirs(module_path, exist_ok=True)
    for file_name, content in files.items():
        with open(os.path.join(module_path, file_name), "w") as f:
            f.write(content)
    print(f"Module '{module_name}' created at '{module_path}' with files populated.")

# Create main.tf file in the project root to call the modules
main_tf_content = """
module "storage" {
  source          = "./modules/storage"
  bucket_name     = "chantowebtest"
  bucket_location = "US"
}

module "networking" {
  source              = "./modules/networking"
  global_address_name = "website-lb-ip"
  dns_zone_name       = "testchanto"
}

module "ssl_certificate" {
  source               = "./modules/ssl_certificate"
  ssl_certificate_name = "website-cert"
  domain_name          = module.networking.dns_record
}

module "load_balancer" {
  source              = "./modules/load_balancer"
  backend_bucket_name = "website-backend"
  bucket_name         = module.storage.bucket_name
  url_map_name        = "website-url-map"
  target_proxy_name   = "website-target-proxy"
  forwarding_rule_name = "website-forwarding-rule"
  ssl_certificate     = module.ssl_certificate.ssl_certificate_self_link
  global_address      = module.networking.global_ip_address
}
"""

with open("main.tf", "w") as f:
    f.write(main_tf_content)
print("Main configuration 'main.tf' generated with module references.")
