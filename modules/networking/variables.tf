
        variable "global_address_name" {
          description = "Name for the reserved global IP address"
          type        = string
          default     = "website1-lb-ip"
        }

        variable "dns_zone_name" {
          description = "DNS Zone name"
          type        = string
        }

        variable "project_id" {
          description = "The GCP project ID"
          type        = string
        }
        