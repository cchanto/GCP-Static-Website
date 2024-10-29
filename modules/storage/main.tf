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
