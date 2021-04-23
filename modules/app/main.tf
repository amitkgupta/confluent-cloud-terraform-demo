resource "kubernetes_service_account" "producer" {
  metadata {
    name = var.app_name
  }
}

resource "kubernetes_service" "producer" {
  metadata {
    name = var.app_name
  }

  spec {
    cluster_ip = "None"
  }
}

resource "kubernetes_stateful_set" "producer" {
  metadata {
    name = var.app_name
  }

  spec {
    service_name          = var.app_name
    pod_management_policy = "Parallel"
    replicas              = 5

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }

        annotations = {
          "vault.hashicorp.com/agent-inject"                            = "true"
          "vault.hashicorp.com/role"                                    = var.app_name
          "vault.hashicorp.com/agent-inject-secret-client.properties"   = "secret/data/${var.app_name}/client-properties"
          "vault.hashicorp.com/agent-inject-template-client.properties" = <<-EOF
            {{- with secret "secret/data/${var.app_name}/client-properties" -}}
            sasl.mechanism=PLAIN
            bootstrap.servers={{ .Data.data.bootstrap_servers }}
            sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
            username="{{ .Data.data.api_key }}" password="{{ .Data.data.api_secret }}";
            security.protocol=SASL_SSL
            client.dns.lookup=use_all_dns_ips
            {{- end }}
            EOF
        }
      }

      spec {
        service_account_name = var.app_name
        container {
          name    = "producer"
          image   = "confluentinc/cp-kafka:latest"
          command = ["/bin/sh", "-c", "kafka-producer-perf-test --topic test --record-size 64 --throughput 1 --producer.config /vault/secrets/client.properties --num-records 230400"]
        }
      }
    }
  }
}