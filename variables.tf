variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "default"
}

variable "microservices" {
  description = "List of microservices"
  type        = list(string)
  default     = ["authentication", "ticket", "experience", "merchant", "customer", "order", "notification", "cart", "payment"]
}

variable "storage_microservices" {
  description = "List of storage microservices"
  type        = list(string)
  default     = ["pass", "asset"]
}

variable "kafka_chart_version" {
  description = "Kafka Helm chart version"
  type        = string
  default     = "22.0.0"
}

variable "postgres_chart_version" {
  description = "PostgreSQL Helm chart version"
  type        = string
  default     = "12.1.6"
}

variable "kafka_credentials" {
    description = "Kafka credentials"
    type        = map(string)
    default     = {
      username = ""
      password = ""
    }
}

variable "postgres_credentials" {
    description = "PostgreSQL credentials"
    type        = map(string)
    default     = {
      username = ""
      password = ""
      database = ""
    }
}

variable host {
    description = "Host"
    type        = string
    default     = "0.0.0.0"
}

variable "port" {
    description = "Port"
    type        = number
    default     = 3000
}

variable "frontend_url" {
  description = "Frontend URL"
  type        = string
  default     = "http://localhost:3000"
}

variable "backend_url" {
  description = "Backend URL"
  type        = string
  default     = "http://localhost"
}

variable "jwt_secret" {
  description = "JWT secret"
  type        = string
  default     = ""
}

variable "auth0" {
    description = "Auth0"
    type        = map(string)
    default     = {
      issuer_url = ""
      audience   = "https://localhost:3001"
      client_id  = ""
      client_secret = ""
      callback_url = "http://localhost/auth/callback"
      domain = ""
      cookie_domain = "localhost"
    }
}

variable "email" {
  description = "Email"
  type        = map(string)
  default     = {
    host         = "smtp.eu.mailgun.org"
    port         = "465"
    secure       = "true"
    username     = ""
    password     = ""
    from_name    = "Ticketpond"
    from_address = ""
  }
}

variable "wallet" {
    description = "Apple Wallet"
    type        = map(string)
    default     = {
      pass_type_identifier = ""
      organization_name    = ""
      team_identifier      = ""
      passphrase           = ""
    }
}

variable "stripe" {
    description = "Stripe"
    type        = map(string)
    default     = {
      secret_key     = ""
      webhook_secret = ""
    }
}
