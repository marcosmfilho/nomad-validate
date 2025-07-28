job "notification-service" {
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

  group "notification" {
    count = 1

    network {
      port "http" {
        to = 3002
      }
    }

    service {
      name = "notification-service"
      port = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.notification.rule=PathPrefix(`/notification`)",
      ]
    }

    task "notification" {
      driver = "docker"

      config {
        image = "ghcr.io/marcosmfilho/notification-service:1.0.0"
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
