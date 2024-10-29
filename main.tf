# resource "kubernetes_namespace" "ticketpond" {
#   metadata {
#     name = var.namespace
#   }
# }

resource "helm_release" "kafka" {
  name       = "kafka"
  namespace  = var.namespace
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "kafka"
  version    = "30.1.0"

  set_list {
    name = "sasl.client.users"
    value = [
      var.kafka_credentials.username
    ]
  }

  set_list {
    name = "sasl.client.passwords"
    value = [
        var.kafka_credentials.password
    ]
  }

  set {
    name  = "extraConfig.autoCreateTopicsEnable"
    value = "true"
  }
}

resource "helm_release" "postgresql" {
  name       = "postgresql"
  namespace  = var.namespace
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "15.5.31"

  set {
    name  = "global.postgresql.auth.username"
    value = var.postgres_credentials.username
  }

  set {
    name  = "global.postgresql.auth.password"
    value = var.postgres_credentials.password
  }

  set {
    name  = "global.postgresql.auth.database"
    value = var.postgres_credentials.database
  }
}

resource "kubernetes_config_map" "ticketpond_config" {
    metadata {
        name      = "ticketpond-config"
        namespace = var.namespace
    }

    data = {
      "NODE_ENV" = "production"
      "KAFKA_BROKER" = "kafka.${var.namespace}.svc.cluster.local:9092"
      "FRONTEND_URL"= var.frontend_url
      "BACKEND_URL"= var.backend_url
      "AUTH0_AUDIENCE"= var.auth0.audience
      "COOKIE_DOMAIN"= var.auth0.cookie_domain
      "HOST"=var.host
      "PORT"=var.port
      "EMAIL_HOST"=var.email.host
      "EMAIL_PORT"=var.email.port
      "EMAIL_SECURE"=var.email.secure
      "EMAIL_FROM_NAME"=var.email.from_name
      "EMAIL_FROM_ADDRESS"=var.email.from_address
      "WALLET_PASS_TYPE_IDENTIFIER"=var.wallet.pass_type_identifier
      "WALLET_ORGANIZATION_NAME"=var.wallet.organization_name
    }
}

resource "kubernetes_secret" "ticketpond_secret" {
  metadata {
    name      = "ticketpond-secret"
    namespace = var.namespace
  }

  data = {
    "DATABASE_URL" = "postgres://${var.postgres_credentials.username}:${var.postgres_credentials.password}@${helm_release.postgresql.name}:5432/${var.postgres_credentials.database}"
    "KAFKA_USERNAME" = var.kafka_credentials.username
    "KAFKA_PASSWORD" = var.kafka_credentials.password
    "EMAIL_USERNAME"=var.email.username
    "EMAIL_PASSWORD"=var.email.password
    "WALLET_TEAM_IDENTIFIER"=var.wallet.team_identifier
    "WALLET_PASSPHRASE"=var.wallet.passphrase
    "STRIPE_SECRET_KEY"=var.stripe.secret_key
    "AUTH0_ISSUER_URL"= var.auth0.issuer_url
    "AUTH0_CLIENT_ID"= var.auth0.client_id
    "AUTH0_CLIENT_SECRET"= var.auth0.client_secret
    "AUTH0_CALLBACK_URL"= var.auth0.callback_url
    "AUTH0_DOMAIN"= var.auth0.domain
    "STRIPE_WEBHOOK_ENDPOINT_SECRET"=var.stripe.webhook_secret
    "JWT_SECRET"=var.jwt_secret
  }
}

resource "kubernetes_persistent_volume" "ticketpond_volume" {
  metadata {
    name = "ticketpond-volume"
  }
  spec {
    capacity = {
      storage = "1Gi"
    }
    storage_class_name = "standard"
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      host_path {
        path = "/volume/ticketpond"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "ticketpond_static" {
  metadata {
    name      = "ticketpond-static"
    namespace = var.namespace
  }

  spec {
    volume_name = kubernetes_persistent_volume.ticketpond_volume.metadata[0].name
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
          storage = "500Mi"
      }
    }
  }
}



resource "kubernetes_deployment" "microservices" {
  for_each = toset(var.microservices)

  metadata {
    name      = each.value
    namespace = var.namespace
    labels = {
      app = each.value
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = each.value
      }
    }

    template {
      metadata {
        labels = {
          app = each.value
        }
      }

      spec {
        container {
          name  = each.value
          image = "ticketpond-${each.value}:latest"

          image_pull_policy = "Never"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.ticketpond_config.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.ticketpond_secret.metadata[0].name
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "storage_microservices" {
  for_each = toset(var.storage_microservices)

  metadata {
    name      = each.value
    namespace = var.namespace
    labels = {
      app = each.value
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = each.value
      }
    }

    template {
      metadata {
        labels = {
          app = each.value
        }
      }

      spec {
        volume {
          name = "ticketpond-static"
          persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.ticketpond_static.metadata[0].name
          }
        }
        container {
          name  = each.value
          image = "ticketpond-${each.value}:latest"

          image_pull_policy = "Never"

          volume_mount {
            mount_path = "/static"
            name       = kubernetes_persistent_volume_claim.ticketpond_static.metadata[0].name
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.ticketpond_config.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.ticketpond_secret.metadata[0].name
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "microservices" {
  for_each = kubernetes_deployment.microservices

  metadata {
    name      = each.value.metadata[0].name
    namespace = var.namespace
    labels = {
      app = each.value.metadata[0].labels.app
    }
  }

  spec {
    selector = {
      app = each.value.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 3000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "storage_microservices" {
  for_each = kubernetes_deployment.storage_microservices

  metadata {
    name      = each.value.metadata[0].name
    namespace = var.namespace
    labels = {
      app = each.value.metadata[0].labels.app
    }
  }

  spec {
    selector = {
      app = each.value.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 3000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "ingress_microservices" {
    for_each = kubernetes_service.microservices
  metadata {
    name      = "${each.value.metadata[0].name}-ingress"
    namespace = var.namespace
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "localhost"

      http {
        path {
          path = "/${each.value.metadata[0].labels.app}"
          path_type = "Prefix"
          backend {
            service {
              name = each.value.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "ingress_storage_microservices" {
    for_each = kubernetes_service.storage_microservices
  metadata {
    name      = "${each.value.metadata[0].name}-ingress"
    namespace = var.namespace
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "localhost"

      http {
        path {
          path = "/${each.value.metadata[0].labels.app}"
          path_type = "Prefix"
          backend {
            service {
              name = each.value.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
