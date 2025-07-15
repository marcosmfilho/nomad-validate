job "grafana" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  group "grafana" {
    network {
      port "web" {
        static = 3005
      }
    }

    volume "grafana_data" {
      type      = "host"
      read_only = false
      source    = "grafana_data"
    }

    service {
      name     = "grafana"
      provider = "nomad"
      port     = "web"
      tags = ["traefik.enable=false"]

      check {
        name     = "alive"
        type     = "tcp"
        port     = "web"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "grafana" {
      driver = "docker"

      config {
        image        = "grafana/grafana:10.4.2"
        ports        = ["web"]
        network_mode = "host"
        volumes = [
          "local/grafana.ini:/etc/grafana/grafana.ini"
        ]
      }

      template {
        data = <<EOF
        [server]
        http_port = 3005

        [auth.anonymous]
        enabled = true
        org_role = Admin

        [security]
        admin_user = admin
        admin_password = admin

        [datasources]
          [[datasources]]
          name = Prometheus
          type = prometheus
          access = proxy
          url = http://127.0.0.1:9090
          isDefault = true
        EOF

        destination = "local/grafana.ini"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      volume_mount {
        volume      = "grafana_data"
        destination = "/var/lib/grafana"
        read_only   = false
      }
    }
  }
}
