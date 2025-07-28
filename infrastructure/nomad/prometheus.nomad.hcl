job "prometheus" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  update {
        max_parallel      = 1
        health_check      = "checks"
        min_healthy_time  = "10s"
        healthy_deadline  = "20m"
        progress_deadline = "30m"
        auto_revert       = false
        auto_promote      = false
        canary            = 0
        stagger           = "30s"
  }

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
    }

    task "prometheus" {
      driver = "docker"

      config {
        image        = "prom/prometheus:latest"
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
                  - targets: ["10.0.0.6:9090"]

              - job_name: "nomad-server-1"
                metrics_path: /v1/metrics
                params:
                  format: [prometheus]
                static_configs:
                  - targets: ["10.0.0.3:4648"]

              - job_name: "nomad-server-2"
                metrics_path: /v1/metrics
                params:
                  format: [prometheus]
                static_configs:
                  - targets: ["10.0.0.2:4648"]

              - job_name: "nomad-server-3"
                metrics_path: /v1/metrics
                params:
                  format: [prometheus]
                static_configs:
                  - targets: ["10.0.0.4:4648"]

              - job_name: "nomad-client-1"
                metrics_path: /v1/metrics
                params:
                  format: [prometheus]
                static_configs:
                  - targets: ["10.0.0.5:4646"]

              - job_name: "nomad-client-2"
                metrics_path: /v1/metrics
                params:
                  format: [prometheus]
                static_configs:
                  - targets: ["10.0.0.6:4646"]

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
