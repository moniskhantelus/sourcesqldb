/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  master_instance_name = var.random_instance_name ? "${var.name}-${random_id.suffix[0].hex}" : var.name

  ip_configuration_enabled = length(keys(var.ip_configuration)) > 0 ? true : false

  ip_configurations = {
    enabled  = var.ip_configuration
    disabled = {}
  }

  databases = { for db in var.additional_databases : db.name => db }
  users     = { for u in var.additional_users : u.name => u }

  retained_backups = lookup(var.backup_configuration, "retained_backups", null)
  retention_unit   = lookup(var.backup_configuration, "retention_unit", null)

  // Force the usage of connector_enforcement
  connector_enforcement = var.connector_enforcement ? "REQUIRED" : "NOT_REQUIRED"
}

resource "random_id" "suffix" {
  count = var.random_instance_name ? 1 : 0

  byte_length = 4
}

resource "random_password" "root-password" {
  length  = 8
  special = true
}

resource "google_sql_database_instance" "default" {
  provider            = google-beta
  project             = var.project_id
  name                = var.random_instance_name ? "${var.name}-${random_id.suffix[0].hex}" : var.name
  database_version    = var.database_version
  region              = var.region
  encryption_key_name = var.encryption_key_name
  root_password       = coalesce(var.root_password, random_password.root-password.result)
  deletion_protection = var.deletion_protection

  settings {
    tier                        = var.tier
    edition                     = var.edition
    activation_policy           = var.activation_policy
    availability_type           = var.availability_type
    deletion_protection_enabled = var.deletion_protection_enabled
    connector_enforcement       = local.connector_enforcement
    dynamic "backup_configuration" {
      for_each = var.backup_configuration.enabled ? [var.backup_configuration] : []
      content {
        enabled                        = lookup(backup_configuration.value, "enabled", null)
        start_time                     = lookup(backup_configuration.value, "start_time", null)
        location                       = lookup(backup_configuration.value, "location", null)
        transaction_log_retention_days = lookup(backup_configuration.value, "transaction_log_retention_days", null)
        point_in_time_recovery_enabled = lookup(backup_configuration.value, "point_in_time_recovery_enabled",null)
        dynamic "backup_retention_settings" {
          for_each = local.retained_backups != null || local.retention_unit != null ? [var.backup_configuration] : []
          content {
            retained_backups = local.retained_backups
            retention_unit   = local.retention_unit
          }
        }
      }
    }
    dynamic "ip_configuration" {
      for_each = [local.ip_configurations[local.ip_configuration_enabled ? "enabled" : "disabled"]]
      content {
        ipv4_enabled                                  = lookup(ip_configuration.value, "ipv4_enabled", null)
        private_network                               = lookup(ip_configuration.value, "private_network", null)
        ssl_mode                                      = lookup(ip_configuration.value, "ssl_mode", "ENCRYPTED_ONLY")
        allocated_ip_range                            = lookup(ip_configuration.value, "allocated_ip_range", null)
        
        dynamic "authorized_networks" {
          for_each = lookup(ip_configuration.value, "authorized_networks", [])
          content {
            expiration_time = lookup(authorized_networks.value, "expiration_time", null)
            name            = lookup(authorized_networks.value, "name", null)
            value           = lookup(authorized_networks.value, "value", null)
          }
        }
        dynamic "psc_config" {
          for_each = ip_configuration.value.psc_enabled ? ["psc_enabled"] : []
          content {
            psc_enabled               = ip_configuration.value.psc_enabled
            allowed_consumer_projects = ip_configuration.value.psc_allowed_consumer_projects
          }
        }
      }
    }

    disk_autoresize       = var.disk_autoresize
    disk_autoresize_limit = var.disk_autoresize_limit
    disk_size             = var.disk_size
    disk_type             = var.disk_type
    pricing_plan          = var.pricing_plan
    user_labels           = var.user_labels
    time_zone             = var.time_zone

    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = lookup(database_flags.value, "name", null)
        value = lookup(database_flags.value, "value", null)
      }
    }

    dynamic "active_directory_config" {
      for_each = var.active_directory_config
      content {
        domain = lookup(var.active_directory_config, "domain", null)
      }
    }

    dynamic "sql_server_audit_config" {
      for_each = length(var.sql_server_audit_config) != 0 ? [var.sql_server_audit_config] : []
      content {
        bucket             = lookup(var.sql_server_audit_config, "bucket", null)
        upload_interval    = lookup(var.sql_server_audit_config, "upload_interval", null)
        retention_interval = lookup(var.sql_server_audit_config, "retention_interval", null)
      }
    }

    location_preference {
      zone                   = var.zone
      secondary_zone         = var.secondary_zone
      follow_gae_application = var.follow_gae_application
    }

    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = var.maintenance_window_update_track
    }
  }

  timeouts {
    create = var.create_timeout
    update = var.update_timeout
    delete = var.delete_timeout
  }

  depends_on = [null_resource.module_depends_on]
}

resource "google_sql_database" "default" {
  count      = var.enable_default_db ? 1 : 0
  name       = var.db_name
  project    = var.project_id
  instance   = google_sql_database_instance.default.name
  charset    = var.db_charset
  collation  = var.db_collation
  depends_on = [null_resource.module_depends_on, google_sql_database_instance.default, google_sql_user.default, google_sql_user.additional_users]
  deletion_policy = var.database_deletion_policy
}

resource "google_sql_database" "additional_databases" {
  for_each   = local.databases
  project    = var.project_id
  name       = each.value.name
  charset    = lookup(each.value, "charset", null)
  collation  = lookup(each.value, "collation", null)
  instance   = google_sql_database_instance.default.name
  depends_on = [null_resource.module_depends_on, google_sql_database_instance.default, google_sql_user.default, google_sql_user.additional_users]
  deletion_policy = var.database_deletion_policy
}

resource "random_password" "user-password" {
  keepers = {
    name = google_sql_database_instance.default.name
  }
  min_lower   = 1
  min_numeric = 1
  min_upper   = 1
  length      = var.password_validation_policy_config != null ? (var.password_validation_policy_config.min_length != null ? var.password_validation_policy_config.min_length + 4 : 32) : 32
  special     = var.enable_random_password_special ? true : (var.password_validation_policy_config != null ? (var.password_validation_policy_config.complexity == "COMPLEXITY_DEFAULT" ? true : false) : false)
  min_special = var.enable_random_password_special ? 1 : (var.password_validation_policy_config != null ? (var.password_validation_policy_config.complexity == "COMPLEXITY_DEFAULT" ? 1 : 0) : 0)
  depends_on  = [null_resource.module_depends_on, google_sql_database_instance.default]

  lifecycle {
    ignore_changes = [
      min_lower, min_upper, min_numeric, special, min_special, length
    ]
  }
}

resource "random_password" "additional_passwords" {
  for_each = local.users
  keepers = {
    name = google_sql_database_instance.default.name
  }
  length     = 32
  special    = true
  depends_on = [null_resource.module_depends_on, google_sql_database_instance.default, time_sleep.wait_200_seconds]
}

resource "google_sql_user" "default" {
  count      = var.enable_default_user ? 1 : 0
  name       = var.user_name
  project    = var.project_id
  instance   = google_sql_database_instance.default.name
  password   = coalesce(var.user_password, random_password.user-password.result)
  depends_on = [
    null_resource.module_depends_on, 
    google_sql_database_instance.default, 
    time_sleep.wait_200_seconds,
    google_sql_database_instance.replicas,
  ]
  deletion_policy = var.user_deletion_policy
}

resource "google_sql_user" "additional_users" {
  for_each   = local.users
  project    = var.project_id
  name       = each.value.name
  password   = each.value.random_password ? random_password.additional_passwords[each.value.name].result : each.value.password
  instance   = google_sql_database_instance.default.name
  depends_on = [
    null_resource.module_depends_on, 
    google_sql_database_instance.default, 
    time_sleep.wait_200_seconds,
    google_sql_database_instance.replicas,
  ]
  deletion_policy = var.user_deletion_policy
}

resource "null_resource" "module_depends_on" {
  triggers = {
    value = length(var.module_depends_on)
  }
}

resource "time_sleep" "wait_200_seconds" {
  create_duration = "200s"
  depends_on      = [null_resource.module_depends_on]
}
