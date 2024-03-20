resource "google_service_account" "service_account" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
}

resource "google_project_iam_binding" "logging-role-2" {
  for_each = toset(var.roles)
  project  = var.project_id
  role     = each.value
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

