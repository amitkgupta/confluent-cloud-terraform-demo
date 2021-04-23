variable "cell_number" {
  default = 1
}

variable "confluent_cloud_environment_id" {
  type = string
}

variable "vault_kubernetes_auth_backend_path" {
  default = "kubernetes"
}

variable "vault_address" {
  default = "http://localhost:8200"
}

variable "vault_token" {
  default = "root"
}