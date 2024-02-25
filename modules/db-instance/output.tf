output "db_password" {
  value = google_sql_user.user.password
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
