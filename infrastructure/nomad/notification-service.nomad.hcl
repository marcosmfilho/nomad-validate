job "notification-service" {
  datacenters = ["dc1"]

  group "notification" {
    count = 1

    network {
      port "http" {
        static = 3002
      }
    }

    service {
      name = "notification-service"
      port = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.notification.rule=PathPrefix(`/notification`)",
        "traefik.http.services.notification.loadbalancer.server.port=3003"
      ]

      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "notification" {
      driver = "docker"

      config {
        image = "localhost:5000/notification-service:latest"
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
