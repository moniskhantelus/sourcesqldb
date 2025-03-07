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

variable "project_id" {
  type        = string
  description = "The project ID to manage the Cloud SQL resources"
}

variable "name" {
  type        = string
  description = "The name of the Cloud SQL resources"
}

variable "random_instance_name" {
  type        = bool
  description = "Sets random suffix at the end of the Cloud SQL resource name"
  default     = false
}

// required
variable "database_version" {
  description = "The database version to use: SQLSERVER_2017_STANDARD, SQLSERVER_2017_ENTERPRISE, SQLSERVER_2017_EXPRESS, or SQLSERVER_2017_WEB"
  type        = string
  default     = "SQLSERVER_2017_STANDARD"
}

// required
variable "region" {
  type        = string
  description = "The region of the Cloud SQL resources"
  default     = "northamerica-northeast1"
}
variable "tier" {
  description = "The tier for the master instance."
  type        = string
  default     = "db-custom-2-3840"
}

variable "edition" {
  description = "The edition of the instance can only be ENTERPRISE at this time."
  type        = string
  default     = "ENTERPRISE"
}
variable "data_cache_enabled" {
  type        = bool
  description = "Whether data cache is enabled for the instance. Defaults to false. Feature is only available for ENTERPRISE_PLUS tier and for "
  default     = false
}
variable "zone" {
  type        = string
  description = "The zone for the master instance."
  default     = "northamerica-northeast1-a"
}

variable "secondary_zone" {
  type        = string
  description = "The preferred zone for the secondary/failover instance, it should be something like: `northamerica-northeast1-b`, `northamerica-northeast1-c`."
  default     = null
}

variable "follow_gae_application" {
  type        = string
  description = "A Google App Engine application whose zone to remain in. Must be in the same region as this instance."
  default     = null
}

variable "activation_policy" {
  description = "The activation policy for the master instance.Can be either `ALWAYS`, `NEVER` or `ON_DEMAND`."
  type        = string
  default     = "ALWAYS"
}

variable "availability_type" {
  description = "The availability type for the master instance.This is only used to set up high availability for the MSSQL instance. Can be either `ZONAL` or `REGIONAL`."
  type        = string
  default     = "REGIONAL"
}

variable "disk_autoresize" {
  description = "Configuration to increase storage size."
  type        = bool
  default     = false
}

variable "disk_autoresize_limit" {
  description = "The maximum size to which storage can be auto increased."
  type        = number
  default     = 0
}

variable "disk_size" {
  description = "The disk size for the master instance."
  default     = 10
}

variable "disk_type" {
  description = "The disk type for the master instance."
  type        = string
  default     = "PD_SSD"
}

variable "pricing_plan" {
  description = "The pricing plan for the master instance."
  type        = string
  default     = "PER_USE"
}

variable "maintenance_window_day" {
  description = "The day of week (1-7) for the master instance maintenance."
  type        = number
  default     = 1
}

variable "maintenance_window_hour" {
  description = "The hour of day (0-23) maintenance window for the master instance maintenance."
  type        = number
  default     = 23
}

variable "maintenance_window_update_track" {
  description = "The update track of maintenance window for the master instance maintenance.Can be either `canary` or `stable`."
  type        = string
  default     = "canary"
}

variable "database_flags" {
  description = "The database flags for the master instance. See [more details](https://cloud.google.com/sql/docs/sqlserver/flags)"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "active_directory_config" {
  description = "Active domain that the SQL instance will join."
  type        = map(string)
  default     = {}
}

variable "sql_server_audit_config" {
  description = "SQL server audit config settings."
  type        = map(string)
  default     = {}
}

variable "user_labels" {
  description = "The key/value labels for the master instances."
  type        = map(string)
  default     = {}
}

variable "ip_configuration" {
  description = "The ip configuration for the master instances."
  type = object({
    authorized_networks                           = list(map(string))
    ipv4_enabled                                  = bool
    private_network                               = string
    ssl_mode                                      = string
    allocated_ip_range                            = string
    psc_enabled                                   = bool
    psc_allowed_consumer_projects                 = list(string)
  })
  default = {
    authorized_networks                           = []
    ipv4_enabled                                  = true
    private_network                               = null
    ssl_mode                                      = "ENCRYPTED_ONLY"
    allocated_ip_range                            = null
    psc_enabled                                   = false
    psc_allowed_consumer_projects                 = []
  }
}

variable "backup_configuration" {
  description = "The backup_configuration settings subblock for the database setings"
  type = object({
    enabled                        = bool
    start_time                     = string
    location                       = string
    point_in_time_recovery_enabled = bool
    transaction_log_retention_days = string
    retained_backups               = number
    retention_unit                 = string
  })
  default = {
    enabled                        = true
    start_time                     = "06:00"
    location                       = "northamerica-northeast2"
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = "7"
    retained_backups               = 10
    retention_unit                 = "COUNT"
  }
}

variable "db_name" {
  description = "The name of the default database to create"
  type        = string
  default     = ""
}

variable "db_charset" {
  description = "The charset for the default database"
  type        = string
  default     = ""
}

variable "db_collation" {
  description = "The collation for the default database. Example: 'en_US.UTF8'"
  type        = string
  default     = ""
}

variable "additional_databases" {
  description = "A list of databases to be created in your cluster"
  type = list(object({
    name      = string
    charset   = string
    collation = string
  }))
  default = []
}

variable "user_name" {
  description = "The name of the default user"
  type        = string
  default     = ""
}

variable "user_password" {
  description = "The password for the default user. If not set, a random one will be generated and available in the generated_user_password output variable."
  type        = string
  default     = ""
}

variable "additional_users" {
  description = "A list of users to be created in your cluster. A random password would be set for the user if the `random_password` variable is set."
  type = list(object({
    name            = string
    password        = string
    random_password = bool
  }))
  default = []
  validation {
    condition     = length([for user in var.additional_users : false if user.random_password == true && (user.password != null && user.password != "")]) == 0
    error_message = "You cannot set both password and random_password, choose one of them."
  }
}

variable "root_password" {
  description = "MSSERVER password for the root user. If not set, a random one will be generated and available in the root_password output variable."
  type        = string
  default     = ""
}

variable "create_timeout" {
  description = "The optional timeout that is applied to limit long database creates."
  type        = string
  default     = "15m"
}

variable "update_timeout" {
  description = "The optional timeout that is applied to limit long database updates."
  type        = string
  default     = "15m"
}

variable "delete_timeout" {
  description = "The optional timeout that is applied to limit long database deletes."
  type        = string
  default     = "30m"
}

variable "module_depends_on" {
  description = "List of modules or resources this module depends on."
  type        = list(any)
  default     = []
}

variable "encryption_key_name" {
  description = "The full path to the encryption key used for the CMEK disk encryption"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Used to block Terraform from deleting a SQL Instance."
  type        = bool
  default     = false
}

variable "deletion_protection_enabled" {
  description = "Enables protection of an instance from accidental deletion protection across all surfaces (API, gcloud, Cloud Console and Terraform)."
  type        = bool
  default     = false
}

variable "time_zone" {
  description = "The time zone for SQL instance."
  type        = string
  default     = null
}

variable "connector_enforcement" {
  description = "Enforce that clients use the connector library"
  type        = bool
  default     = false
}

variable "database_deletion_policy" {
  description = "The deletion policy for the database. Setting ABANDON allows the resource to be abandoned rather than deleted. This is useful for Postgres, where databases cannot be deleted from the API if there are users other than cloudsqlsuperuser with access. Possible values are: \"ABANDON\"."
  type        = string
  default     = null
}

variable "password_validation_policy_config" {
  description = "The password validation policy settings for the database instance."
  type = object({
    min_length                  = number
    complexity                  = string
    reuse_interval              = number
    disallow_username_substring = bool
    password_change_interval    = string
  })
  default = null
}

variable "enable_random_password_special" {
  description = "Enable special characters in generated random passwords."
  type        = bool
  default     = false
}

variable "user_deletion_policy" {
  description = "The deletion policy for the user. Setting ABANDON allows the resource to be abandoned rather than deleted. This is useful for Postgres, where users cannot be deleted from the API if they have been granted SQL roles. Possible values are: \"ABANDON\"."
  type        = string
  default     = null
}

variable "enable_default_db" {
  description = "Enable or disable the creation of the default database"
  type        = bool
  default     = true
}

variable "enable_default_user" {
  description = "Enable or disable the creation of the default user"
  type        = bool
  default     = true
}

variable "read_replica_deletion_protection" {
  description = "Used to block Terraform from deleting replica SQL Instances."
  type        = bool
  default     = false
}
variable "read_replica_deletion_protection_enabled" {
  description = "Enables protection of replica instance from accidental deletion across all surfaces (API, gcloud, Cloud Console and Terraform)."
  type        = bool
  default     = false
}

variable "read_replica_name_suffix" {
  description = "The optional suffix to add to the read instance name"
  type        = string
  default     = ""
}

// Read Replicas
variable "read_replicas" {
  description = "List of read replicas to create. Encryption key is required for replica in different region. For replica in same region as master set encryption_key_name = null"
  type = list(object({
    name                  = string
    name_override         = string
    tier                  = string
    edition               = string
    availability_type     = string
    zone                  = string
    disk_autoresize       = bool
    disk_autoresize_limit = number
    disk_size             = string
    database_flags = list(object({
      name  = string
      value = string
    }))
    ip_configuration = object({
      authorized_networks                           = list(map(string))
      ipv4_enabled                                  = bool
      private_network                               = string
      ssl_mode                                      = string
      allocated_ip_range                            = string
      enable_private_path_for_google_cloud_services = bool
      psc_enabled                                   = bool
      psc_allowed_consumer_projects                 = list(string)
    })
    encryption_key_name = string
  }))
  default = []
}
variable "query_insights_enabled" {
  description = "Enable Query Insights for Cloud SQL instance"
  type        = bool
}
variable "query_string_length" {
  description = "Query String length for Query insights"
type = number
}
variable "sqlauditbucket"{
  description = "Bucket location for SQL Audit bucket"
  type = string
}
