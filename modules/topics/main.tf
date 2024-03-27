resource "google_pubsub_topic" "topic" {
  name                       = var.name
  message_retention_duration = var.message_retention_duration
}
