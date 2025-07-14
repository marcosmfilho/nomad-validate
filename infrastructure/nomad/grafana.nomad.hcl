job "grafana" {
  datacenters = ["dc1"]

  group "grafana" {
    count = 1

    network {
      port "web" {
        static = 3000
      }
    }

    service {
      name = "grafana"
      port = "web"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.grafana.rule=PathPrefix(`/grafana`)",
        "traefik.http.services.grafana.loadbalancer.server.port=3000"
      ]

      check {
        type     = "http"
        path     = "/login"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:10.2.0"
        ports = ["web"]
      }

      env {
        GF_SECURITY_ADMIN_USER     = "admin"
        GF_SECURITY_ADMIN_PASSWORD = "admin"
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
