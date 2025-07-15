server {
  enabled = true
  bootstrap_expect = 3
  server_join {
    retry_join = ["192.168.0.126:4658", "192.168.0.126:4668"]
  }
}

bind_addr = "0.0.0.0"
data_dir  = "/tmp/nomad/server1"
name      = "server1"

ports {
  http = 4670
  rpc  = 4671
  serf = 4672
}

advertise {
  http = "192.168.0.126:4670"
  rpc  = "192.168.0.126:4671"
  serf = "192.168.0.126:4672"
}

telemetry {
  prometheus_metrics         = true
  collection_interval        = "5s"
  publish_allocation_metrics = true
  publish_node_metrics       = true
}