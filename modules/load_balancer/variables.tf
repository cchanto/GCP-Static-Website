
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
  description = "Name for the reserved global IP address"
  type        = string
  default     = "website-lb-ip"  # Ensure this is a valid name
}


variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default = "poc-test-infra"
}
        