output "db_password" {
  value = random_password.db_password.result
}

output "db_username" {
  value = google_sql_user.user.name

}

output "db_host" {
  value = google_sql_database_instance.default.private_ip_address
}

output "db_name" {
  value = google_sql_database.database.name
}
