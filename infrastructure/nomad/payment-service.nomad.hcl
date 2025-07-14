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

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.payment.rule=PathPrefix(`/payment`)",
        "traefik.http.services.payment.loadbalancer.server.port=3001"
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
        image = "payment-service:latest"
        ports = ["http"]
      }

      env {
        RABBITMQ_URL = "amqp://rabbitmq.service.consul:5672"
      }

      resources {
        cpu    = 200
        memory = 128
      }
    }
  }
}
