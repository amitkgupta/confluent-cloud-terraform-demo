# Confluent Cloud Terraform Demo

## Prerequisites

* Google Cloud Platform project
* Confluent Cloud account
* `git`
* `gcloud`
* `kubectl`
* `helm`
* `terraform`

## Clone Repo

```
$ git clone git@github.com:amitkgupta/confluent-cloud-terraform-demo.git \
  /tmp/confluent-cloud-terraform-demo

$ cd /tmp/confluent-cloud-terraform-demo
```

## Create Kubernetes Cluster

```
$ gcloud container clusters create cluster-1 \
  --project <YOUR_GCP_PROJECT_ID> \
  --zone us-central1-c \
  --cluster-version 1.18.16-gke.502 \
  --num-nodes 3 \
  --enable-autoscaling \
  --min-nodes 0 \
  --max-nodes 12

$ gcloud container clusters get-credentials cluster-1 --zone us-central1-c --project <YOUR_GCP_PROJECT_ID>
```

## Install Vault and Initialize

```
$ helm repo add hashicorp https://helm.releases.hashicorp.com

$ helm install vault hashicorp/vault --set server.dev.enabled=true

$ kubectl exec -it vault-0 -- /bin/sh

/ $ vault secrets enable -path=internal kv-v2

/ $ vault auth enable kubernetes

/ $ vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://${KUBERNETES_PORT_443_TCP_ADDR}:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

/ $ exit
```

## Set Environment Variables for Terraform

```
$ export CONFLUENT_CLOUD_USERNAME=<YOUR_CONFLUENT_CLOUD_EMAIL>

$ export CONFLUENT_CLOUD_PASSWORD=<YOUR_CONFLUENT_CLOUD_PASSWORD>
```

## Expose Vault Locally for Terraform

In a separate shell session, run the following:

```
$ kubectl port-forward vault-0 8200
```

## Create Kafka Cells in Confluent Cloud and Launch Producer Apps in Kubernetes

```
$ terraform init

$ terraform apply
```

## Log Into the Confluent Cloud UI and See Data Flow

😁

## Next Steps

1. Create an (N+1)-st Kafka cluster for aggregation via Terraform.
1. Establish Cluster Links between the N Kafka clusters and the aggregate cluster via Terraform.
1. Mirror `test` topic from cluster `i` into `test-${i}` in the aggregate cluster via Terraform.
1. Create ksqlDB app in aggregate cluster to join `test-${i}` topics together via Terraform.
