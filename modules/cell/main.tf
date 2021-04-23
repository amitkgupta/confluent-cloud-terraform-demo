terraform {
  required_providers {
    confluentcloud = {
      source = "Mongey/confluentcloud"
    }
    kafka = {
      source  = "Mongey/kafka"
      version = "0.2.11"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

provider "confluentcloud" {}

locals {
  app_name = "producer${var.cell_number}"
}

resource "confluentcloud_service_account" "producer" {
  name        = local.app_name
  description = "Service Account for Producer ${var.cell_number}"
}

resource "confluentcloud_kafka_cluster" "kafka" {
  name             = "kafka${var.cell_number}"
  service_provider = "aws"
  region           = "eu-west-1"
  availability     = "LOW"
  environment_id   = var.confluent_cloud_environment_id
  network_egress   = 100
  network_ingress  = 100
  storage          = 5000

  deployment = {
    sku = "BASIC"
  }
}

resource "confluentcloud_api_key" "admin" {
  cluster_id     = confluentcloud_kafka_cluster.kafka.id
  environment_id = var.confluent_cloud_environment_id
  description    = "Kafka ${var.cell_number} Admin API Key"
}

resource "confluentcloud_api_key" "producer" {
  cluster_id     = confluentcloud_kafka_cluster.kafka.id
  environment_id = var.confluent_cloud_environment_id
  user_id        = confluentcloud_service_account.producer.id
  description    = "Kafka ${var.cell_number} Producer API Key"
}

provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

resource "vault_generic_secret" "client_properties" {
  path = "secret/${local.app_name}/client-properties"

  data_json = jsonencode({
    bootstrap_servers = confluentcloud_kafka_cluster.kafka.bootstrap_servers
    api_key           = confluentcloud_api_key.producer.key
    api_secret        = confluentcloud_api_key.producer.secret
  })
}

resource "vault_policy" "producer" {
  name = local.app_name

  policy = <<EOT
path "${replace(vault_generic_secret.client_properties.path, "secret", "secret/data")}" {
  capabilities = ["read"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "producer" {
  backend                          = var.vault_kubernetes_auth_backend_path
  role_name                        = local.app_name
  bound_service_account_names      = [local.app_name]
  bound_service_account_namespaces = ["default"]
  token_ttl                        = 24 * 60 * 60
  token_policies                   = [vault_policy.producer.name]
}


provider "kafka" {
  bootstrap_servers = [replace(confluentcloud_kafka_cluster.kafka.bootstrap_servers, "SASL_SSL://", "")]

  tls_enabled    = true
  sasl_username  = confluentcloud_api_key.admin.key
  sasl_password  = confluentcloud_api_key.admin.secret
  sasl_mechanism = "plain"
  timeout        = 10
}

resource "kafka_topic" "test" {
  name               = "test"
  replication_factor = 3
  partitions         = 1
  config = {
    "cleanup.policy" = "delete"
  }
}

resource "kafka_acl" "test" {
  resource_name       = "test"
  resource_type       = "Topic"
  acl_principal       = "User:${confluentcloud_service_account.producer.id}"
  acl_operation       = "All"
  acl_permission_type = "Allow"
  acl_host            = "*"
}