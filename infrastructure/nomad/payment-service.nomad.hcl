job "payment-service" {

  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel      = 1
    health_check      = "checks"
    min_healthy_time  = "30s"
    healthy_deadline  = "3m"
    progress_deadline = "5m"
    auto_revert       = false
    auto_promote      = true
    canary            = 2
    stagger           = "15s"
  }

  group "payment" {
    count = 1

    network {
      port "http" {
        to = 3001
      }
    }

    service {
      name = "payment-service"
      port = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.payment.rule=PathPrefix(`/payment`)",
      ]
    }

    task "payment" {
      driver = "docker"

      config {
        image = "ghcr.io/marcosmfilho/payment-service:1.0.0"
        ports = ["http"]
      }

      template {
        data = <<EOT
          RABBITMQ_URL=amqp://{{ range nomadService "rabbitmq" }}{{ .Address }}:{{ .Port }}{{ end }}
        EOT
        destination = "secrets/env_vars.env"
        env         = true
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
