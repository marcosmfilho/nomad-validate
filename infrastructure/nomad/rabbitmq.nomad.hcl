job "rabbitmq" {
  datacenters = ["dc1"]
  type        = "service"

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