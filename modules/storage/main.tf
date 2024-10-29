
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
        