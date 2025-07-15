server {
  enabled = true
  bootstrap_expect = 3
  server_join {
    retry_join = ["192.168.0.126:4672"]
  }
}

bind_addr = "0.0.0.0"
data_dir  = "/tmp/nomad/server2"
name      = "server2"

ports {
  http = 4656
  rpc  = 4657
  serf = 4658
}

advertise {
  http = "192.168.0.126"
  rpc  = "192.168.0.126"
  serf = "192.168.0.126"
}

telemetry {
  prometheus_metrics         = true
  collection_interval        = "5s"
  publish_allocation_metrics = true
  publish_node_metrics       = true
}