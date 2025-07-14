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

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.order.rule=PathPrefix(`/order`)",
        "traefik.http.services.order.loadbalancer.server.port=3000"
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
        image = "order-service:latest"
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
