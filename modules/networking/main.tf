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