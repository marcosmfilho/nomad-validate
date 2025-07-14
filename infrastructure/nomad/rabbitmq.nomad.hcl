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
    }

    task "rabbitmq" {
      driver = "docker"

      config {
        image = "rabbitmq:3.13-management"
        ports = ["amqp", "management"]
        hostname = "rabbitmq"
      }

      resources {
        cpu    = 300
        memory = 256
      }
    }
  }
}
