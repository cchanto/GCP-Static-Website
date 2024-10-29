
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
        