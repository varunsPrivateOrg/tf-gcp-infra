resource "google_dns_record_set" "frontend" {
  name = var.dns_record_name
  type = var.recordType
  ttl  = var.ttl

  managed_zone = data.google_dns_managed_zone.managed_zone.name

  rrdatas = var.publicIps
}

data "google_dns_managed_zone" "managed_zone" {
  name = var.dns_managed_zone
}
