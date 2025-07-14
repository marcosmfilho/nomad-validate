job "rabbitmq" {
  datacenters = ["dc1"]

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
      name = "rabbitmq"
      port = "amqp"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "rabbit" {
      driver = "docker"

      config {
        image = "rabbitmq:3-management"
        ports = ["amqp", "management"]
      }

      resources {
        cpu    = 300
        memory = 256
      }

      env {
        RABBITMQ_DEFAULT_USER = "guest"
        RABBITMQ_DEFAULT_PASS = "guest"
      }
    }
  }
}