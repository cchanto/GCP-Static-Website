
module "storage" {
  source          = "./modules/storage"
  bucket_name     = "chantowebtest"
  bucket_location = "US"
}

module "networking" {
  source              = "./modules/networking"
  global_address_name = "website-lb-ip"
  dns_zone_name       = "testchanto"
}

module "ssl_certificate" {
  source               = "./modules/ssl_certificate"
  ssl_certificate_name = "website-cert"
  domain_name          = module.networking.dns_record
}

module "load_balancer" {
  source              = "./modules/load_balancer"
  backend_bucket_name = "website-backend"
  bucket_name         = module.storage.bucket_name
  url_map_name        = "website-url-map"
  target_proxy_name   = "website-target-proxy"
  forwarding_rule_name = "website-forwarding-rule"
  ssl_certificate     = module.ssl_certificate.ssl_certificate_self_link
  global_address      = module.networking.global_ip_address
}
