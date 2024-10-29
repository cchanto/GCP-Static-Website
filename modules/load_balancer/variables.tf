
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

