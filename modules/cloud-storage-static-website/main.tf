
terraform {
  required_version = ">= 0.12.26"
}


locals {

  website_domain_name_dashed = replace(var.website_domain_name, ".", "-")
  access_log_kms_keys        = var.access_logs_kms_key_name == "" ? [] : [var.access_logs_kms_key_name]
  website_kms_keys           = var.website_kms_key_name == "" ? [] : [var.website_kms_key_name]
}



resource "google_storage_bucket" "website" {
  provider = google-beta

  project = var.project

  name          = var.website_domain_name
  location      = var.website_location
  storage_class = var.website_storage_class

  versioning {
    enabled = var.enable_versioning
  }

  website {
    main_page_suffix = var.index_page
    not_found_page   = var.not_found_page
  }

  dynamic "cors" {
    for_each = var.enable_cors ? ["cors"] : []
    content {
      origin          = var.cors_origins
      method          = var.cors_methods
      response_header = var.cors_extra_headers
      max_age_seconds = var.cors_max_age_seconds
    }
  }

  force_destroy = var.force_destroy_website

  dynamic "encryption" {
    for_each = local.website_kms_keys
    content {
      default_kms_key_name = encryption.value
    }
  }

  labels = var.custom_labels
  logging {
    log_bucket        = google_storage_bucket.access_logs.name
    log_object_prefix = var.access_log_prefix != "" ? var.access_log_prefix : local.website_domain_name_dashed
  }
}



resource "google_storage_default_object_acl" "website_acl" {
  provider    = google-beta
  bucket      = google_storage_bucket.website.name
  role_entity = var.website_acls
  #role_entity = ["READER:allUsers"]
}



resource "google_storage_bucket" "access_logs" {
  provider = google-beta

  project = var.project


  name          = "${local.website_domain_name_dashed}-logs"
  location      = var.website_location
  storage_class = var.website_storage_class

  #force_destroy = var.force_destroy_access_logs_bucket
  force_destroy = true

  dynamic "encryption" {
    for_each = local.access_log_kms_keys
    content {
      default_kms_key_name = encryption.value
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age = var.access_logs_expiration_time_in_days
    }
  }
  labels = var.custom_labels
}

# ---------------------------------------------------------------------------------------------------------------------
# GRANT WRITER ACCESS TO GOOGLE ANALYTICS
# ---------------------------------------------------------------------------------------------------------------------

resource "google_storage_bucket_acl" "analytics_write" {
  provider = google-beta

  bucket = google_storage_bucket.access_logs.name
  role_entity = ["WRITER:group-cloud-storage-analytics@google.com"]
}
