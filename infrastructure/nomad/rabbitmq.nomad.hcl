job "rabbitmq" {
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
  
  group "rabbit" {
    count = 1

    network {
      port "amqp" {
        static = 5672
      }

      port "management" {
        static = 15672
      }
    }

    service {
      name     = "rabbitmq"
      port     = "amqp"
      provider = "nomad"
      tags = ["traefik.enable=false"]

      check_restart {
        limit           = 3
        grace           = "30s"
        ignore_warnings = true
      }
    }

    task "rabbitmq" {
      driver = "docker"

      config {
        image    = "rabbitmq:3.13-management"
        ports    = ["amqp", "management"]
        hostname = "rabbitmq"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}