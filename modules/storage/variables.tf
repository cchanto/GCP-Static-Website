
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
        