job "prometheus" {
  datacenters = ["dc1"]

  group "prometheus" {
    count = 1

    network {
      port "web" {
        static = 9090
      }
    }

    service {
      name = "prometheus"
      port = "web"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.prom.rule=PathPrefix(`/prometheus`)",
        "traefik.http.services.prom.loadbalancer.server.port=9090"
      ]

      check {
        type     = "http"
        path     = "/-/healthy"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:v2.52.0"
        ports = ["web"]
        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml"
        ]
      }

      template {
        data        = <<EOF
{{ file "infrastructure/prometheus/prometheus.yml" }}
EOF
        destination = "local/prometheus.yml"
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
