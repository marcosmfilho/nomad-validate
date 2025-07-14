job "payment-service" {
  datacenters = ["dc1"]

  group "payment" {
    count = 1

    network {
      port "http" {
        static = 3001
      }
    }

    service {
      name = "payment-service"
      port = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.payment.rule=PathPrefix(`/payment`)",
        "traefik.http.services.payment.loadbalancer.server.port=3002"
      ]

      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "payment" {
      driver = "docker"

      config {
        image = "localhost:5000/payment-service:latest"
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
