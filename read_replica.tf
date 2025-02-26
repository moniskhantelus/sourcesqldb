locals {
  replicas = {
    for x in var.read_replicas : "${var.name}-replica${var.read_replica_name_suffix}${x.name}" => x
  }
}

resource "google_sql_database_instance" "replicas" {
  provider             = google-beta
  for_each             = local.replicas
  project              = var.project_id
  name                 = each.value.name_override == null || each.value.name_override == "" ? "${local.master_instance_name}-replica${var.read_replica_name_suffix}${each.value.name}" : each.value.name_override
  database_version     = var.database_version
  region               = join("-", slice(split("-", lookup(each.value, "zone", var.zone)), 0, 2))
  master_instance_name = google_sql_database_instance.default.name
  deletion_protection  = var.read_replica_deletion_protection
  encryption_key_name  = (join("-", slice(split("-", lookup(each.value, "zone", var.zone)), 0, 2))) == var.region ? null : each.value.encryption_key_name

  replica_configuration {
    failover_target = false
  }

  settings {
    tier                        = lookup(each.value, "tier", var.tier)
    edition                     = lookup(each.value, "edition", var.edition)
    activation_policy           = "ALWAYS"
    availability_type           = lookup(each.value, "availability_type", var.availability_type)
    deletion_protection_enabled = var.read_replica_deletion_protection_enabled

    dynamic "ip_configuration" {
      for_each = [lookup(each.value, "ip_configuration", {})]
      content {
        ipv4_enabled                                  = lookup(ip_configuration.value, "ipv4_enabled", null)
        private_network                               = lookup(ip_configuration.value, "private_network", null)
        ssl_mode                                      = lookup(ip_configuration.value, "ssl_mode", "ENCRYPTED_ONLY")
        allocated_ip_range                            = lookup(ip_configuration.value, "allocated_ip_range", null)
        enable_private_path_for_google_cloud_services = lookup(ip_configuration.value, "enable_private_path_for_google_cloud_services", false)

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
   
    disk_autoresize       = lookup(each.value, "disk_autoresize", var.disk_autoresize)
    disk_autoresize_limit = lookup(each.value, "disk_autoresize_limit", var.disk_autoresize_limit)
    disk_size             = lookup(each.value, "disk_size", var.disk_size)
    disk_type             = lookup(each.value, "disk_type", var.disk_type)
    pricing_plan          = "PER_USE"
    user_labels           = lookup(each.value, "user_labels", var.user_labels)

    dynamic "database_flags" {
      for_each = lookup(each.value, "database_flags", [])
      content {
        name  = lookup(database_flags.value, "name", null)
        value = lookup(database_flags.value, "value", null)
      }
    }

    location_preference {
      zone = lookup(each.value, "zone", var.zone)
    }

  }

  depends_on = [google_sql_database_instance.default]

  lifecycle {
    ignore_changes = [
      settings[0].disk_size,
      settings[0].maintenance_window,
      encryption_key_name,
    ]
  }

  timeouts {
    create = var.create_timeout
    update = var.update_timeout
    delete = var.delete_timeout
  }
}
