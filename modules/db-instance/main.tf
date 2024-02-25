
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "default" {
  name             = "${var.database_instance_config.name_prefix}-${random_id.db_name_suffix.hex}"
  database_version = var.database_instance_config.database_version

  settings {
    tier                        = var.database_instance_config.settings.tier
    deletion_protection_enabled = var.database_instance_config.settings.deletion_protection_enabled
    availability_type           = var.database_instance_config.settings.availability_type
    disk_type                   = var.database_instance_config.settings.disk_type
    disk_size                   = var.database_instance_config.settings.disk_size
    edition                     = var.database_instance_config.settings.edition
    ip_configuration {
      ipv4_enabled    = var.database_instance_config.settings.ip_configuration.ipv4_enabled
      private_network = var.vpc_reference
    }
  }
  deletion_protection = var.database_instance_config.deletion_protection
}

resource "google_sql_database" "database" {
  name            = var.database_config.name
  instance        = google_sql_database_instance.default.name
  deletion_policy = var.database_config.deletion_policy
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"

}

resource "google_sql_user" "user" {
  name     = var.users_config.name
  instance = google_sql_database_instance.default.name
  password = random_password.db_password.result

}
