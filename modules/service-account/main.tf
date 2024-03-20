# resource "google_service_account" "service_account" {
#   account_id   = "some-id"
#   display_name = "Service Account"
# }

# resource "google_project_iam_binding" "logging-role-1" {
#   project = "cloudspring2024-demo-415217"
#   role    = "roles/logging.admin"

#   members = [
#     "serviceAccount:${google_service_account.service_account.email}"
#   ]
# }
# resource "google_project_iam_binding" "logging-role-2" {
#   project = "cloudspring2024-demo-415217"
#   role    = "roles/monitoring.metricWriter"

#   members = [
#     "serviceAccount:${google_service_account.service_account.email}"
#   ]
# }

resource "google_service_account" "service_account" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
}

# resource "google_project_iam_binding" "logging-role-1" {
#   project = var.project_id
#   role    = var.role-1

#   members = [
#     "serviceAccount:${google_service_account.service_account.email}"
#   ]
# }
# resource "google_project_iam_binding" "logging-role-2" {
#   project = var.project_id
#   role    = var.role-2

#   members = [
#     "serviceAccount:${google_service_account.service_account.email}"
#   ]
# }

resource "google_project_iam_binding" "logging-role-2" {
  for_each = toset(var.roles)
  project  = var.project_id
  role     = each.value
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

