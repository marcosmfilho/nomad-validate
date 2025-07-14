job "traefik" {
  datacenters = ["dc1"]

  group "gateway" {
    count = 1

    network {
      port "http" {
        static = 80
      }
    }

    service {
      name = "traefik"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.traefik.rule=PathPrefix(`/traefik`)",
        "traefik.http.services.traefik.loadbalancer.server.port=8080"
      ]

      check {
        type     = "http"
        path     = "/ping"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "proxy" {
      driver = "docker"

      config {
        image = "traefik:v2.10"
        ports = ["http"]

        args = [
          "--entrypoints.web.address=:80",
          "--providers.consulCatalog=true",
          "--providers.consulCatalog.endpoint.address=127.0.0.1:8500",
          "--providers.consulCatalog.endpoint.scheme=http",
          "--providers.consulCatalog.defaultRule=Host(`localhost`)",
          "--api.dashboard=true",
          "--ping=true"
        ]
      }

      resources {
        cpu    = 200
        memory = 128
      }

      env {
        CONSUL_HTTP_ADDR = "http://127.0.0.1:8500"
      }
    }
  }
}