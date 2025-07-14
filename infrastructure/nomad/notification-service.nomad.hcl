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

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.notification.rule=PathPrefix(`/notify`)",
        "traefik.http.services.notification.loadbalancer.server.port=3002"
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
        image = "notification-service:latest"
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