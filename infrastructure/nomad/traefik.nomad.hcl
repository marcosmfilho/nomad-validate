job "traefik" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      port "http" {
        to     = 80
        static = 80
      }

      port "api" {
        to     = 8081
        static = 8081
      }

      port "internal" {
        to     = 8888
        static = 8888
      }
    }

    service {
      name     = "traefik"
      provider = "nomad"
      port     = "http"
    }

    task "traefik" {
      driver = "docker"

      config {
        image  = "traefik:2.11"
        ports  = ["http", "api", "internal"]
        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml"
        ]
      }

      template {
        data = <<EOF
[log]
  level = "DEBUG"

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
      address = "http://nomad-server-1:4646"
  [providers.file]
    directory = "/etc/traefik"
    watch = true
EOF

        destination = "local/traefik.toml"
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}