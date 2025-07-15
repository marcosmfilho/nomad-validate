job "prometheus" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  group "monitoring" {
    network {
      port "web" {
        static = 9090
      }
    }

    service {
      name     = "prometheus"
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

    task "prometheus" {
      driver = "docker"

      config {
        image        = "prom/prometheus:latest"
        network_mode = "host"
        ports        = ["web"]
        volumes      = ["local/prometheus.yml:/etc/prometheus/prometheus.yml"]
      }

      template {
        data = <<EOF
          global:
            scrape_interval: 5s
            evaluation_interval: 5s

          scrape_configs:
            - job_name: "prometheus"
              static_configs:
                - targets: ["localhost:9090"]

            - job_name: "nomad-server1"
              metrics_path: /v1/metrics
              params:
                format: [prometheus]
              static_configs:
                - targets: ["192.168.0.126:4670"]  # porta http do server1

            - job_name: "nomad-server2"
              metrics_path: /v1/metrics
              params:
                format: [prometheus]
              static_configs:
                - targets: ["192.168.0.126:4656"]  # porta http do server2

            - job_name: "nomad-server3"
              metrics_path: /v1/metrics
              params:
                format: [prometheus]
              static_configs:
                - targets: ["192.168.0.126:4666"]  # porta http do server3

            - job_name: "nomad-client1"
              metrics_path: /v1/metrics
              params:
                format: [prometheus]
              static_configs:
                - targets: ["192.168.0.126:5656"]  # client1

            - job_name: "nomad-client2"
              metrics_path: /v1/metrics
              params:
                format: [prometheus]
              static_configs:
                - targets: ["192.168.0.126:5657"]  # client2
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
