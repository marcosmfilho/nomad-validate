job "mongodb" {
  datacenters = ["dc1"]

  group "mongo" {
    count = 1

    network {
      port "db" {
        static = 27017
      }
    }

    service {
      name = "mongodb"
      port = "db"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "mongo" {
      driver = "docker"

      config {
        image = "mongo:5.0"
        ports = ["db"]
      }

      resources {
        cpu    = 300
        memory = 256
      }

      # Descomente se quiser volume persistente depois
      # volume_mount {
      #   volume      = "mongo_data"
      #   destination = "/data/db"
      # }
    }
  }
}