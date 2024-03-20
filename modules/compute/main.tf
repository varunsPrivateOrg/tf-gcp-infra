resource "google_compute_instance" "instance-1" {
  machine_type = var.machine_type
  name         = var.instance_name
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.my_image_datasource.self_link
      size  = var.boot_disk.initialize_params.size
      type  = var.boot_disk.initialize_params.type
    }
  }

  network_interface {
    subnetwork_project = var.network_interface.subnetwork_project
    subnetwork         = var.network_interface.subnetwork
    access_config {
      network_tier = var.network_interface.access_config.network_tier
    }
  }
  tags                    = var.tags
  metadata_startup_script = <<EOF
#!/bin/bash
rm -f /opt/webapp/.env
{
  echo "DB_USERNAME=${var.vpcs_with_db_instance[var.sql_db_environment_configs.vpc_network_name].db_instances_configs[var.sql_db_environment_configs.database_instance_prefix].db_username}"
  echo "DB_NAME=${var.vpcs_with_db_instance[var.sql_db_environment_configs.vpc_network_name].db_instances_configs[var.sql_db_environment_configs.database_instance_prefix].db_name}"
  echo "DB_PASSWORD=${var.vpcs_with_db_instance[var.sql_db_environment_configs.vpc_network_name].db_instances_configs[var.sql_db_environment_configs.database_instance_prefix].db_password}"
  echo "DB_PORT=5432"
  echo "PORT=3000"
  echo "DB_HOST=${var.vpcs_with_db_instance[var.sql_db_environment_configs.vpc_network_name].db_instances_configs[var.sql_db_environment_configs.database_instance_prefix].db_host}"
} > /opt/webapp/.env

echo ".env file has been updated."
EOF

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }
  allow_stopping_for_update = true
}

data "google_compute_image" "my_image_datasource" {
  family  = var.image.family
  project = var.image.project_id
}
