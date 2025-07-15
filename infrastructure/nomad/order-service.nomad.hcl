job "order-service" {
  datacenters = ["dc1"]

  group "order" {
    count = 1

    network {
      port "http" {
        static = 3000
      }
    }

    service {
      name = "order-service"
      port = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.order.rule=PathPrefix(`/order`)"
      ]

      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "order" {
      driver = "docker"

      config {
        image = "localhost:5000/order-service:1.1.0"
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
