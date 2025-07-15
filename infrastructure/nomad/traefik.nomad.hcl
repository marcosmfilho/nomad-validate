job "traefik" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    network {
      port "http" {
        to     = 80
        static = 80
      }

      port "api" {
        static = 8081
      }

      port "internal" {
        static = 8888
      }
    }

    service {
      name     = "traefik"
      provider = "nomad"
      port     = "http"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:2.11"
        network_mode = "host"
        ports        = ["http", "api", "internal"]
        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml"
        ]
      }

      template {
        data = <<EOF
            [log]
              level = "WARN"
            [accessLog]
            [entryPoints]
              [entryPoints.http]
                address = ":80"

              [entryPoints.traefik]
                address = ":8081"

              [entryPoints.internal]
                address = ":8888"

            [api]
              dashboard = true
              insecure  = true

            [metrics]
              [metrics.prometheus]
                addEntryPointsLabels = true
                addServicesLabels = true

            [providers]
              [providers.nomad]
                [providers.nomad.endpoint]
                  address = "http://127.0.0.1:4670"
              # [providers.consulcatalog]
              #   [providers.consulcatalog.endpoint]
              #     address = "http://127.0.0.1:8500"
              [providers.file]
                directory = "/etc/traefik"
                watch = true
        EOF

        destination = "local/traefik.toml"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}