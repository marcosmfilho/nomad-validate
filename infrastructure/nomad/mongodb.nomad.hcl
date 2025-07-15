job "mongodb" {

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
      provider = "nomad"
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

      # volume_mount {
      #   volume      = "mongo_data"
      #   destination = "/data/db"
      # }
    }
  }
}