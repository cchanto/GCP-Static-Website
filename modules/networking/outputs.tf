
        output "dns_record" {
          value = google_dns_record_set.website.name
        }

        output "global_ip_address" {
          value = google_compute_global_address.website.address
        }
        