terraform {
  required_providers {
    confluentcloud = {
      source = "Mongey/confluentcloud"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "confluentcloud" {}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "confluentcloud_environment" "environment" {
  name = "Confluent-Cloud-Terraform-Demo"
}

module "cell1" {
  source = "./modules/cell"

  cell_number                    = 1
  confluent_cloud_environment_id = confluentcloud_environment.environment.id
}

module "app1" {
  source = "./modules/app"

  app_name = module.cell1.role_name
}

module "cell2" {
  source = "./modules/cell"

  cell_number                    = 2
  confluent_cloud_environment_id = confluentcloud_environment.environment.id
}

module "app2" {
  source = "./modules/app"

  app_name = module.cell2.role_name
}

module "cell3" {
  source = "./modules/cell"

  cell_number                    = 3
  confluent_cloud_environment_id = confluentcloud_environment.environment.id
}

module "app3" {
  source = "./modules/app"

  app_name = module.cell3.role_name
}