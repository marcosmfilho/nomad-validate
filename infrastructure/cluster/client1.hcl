client {
  enabled = true
  servers = [
    "192.168.0.126:4671",  # server1
    "192.168.0.126:4657",  # server2
    "192.168.0.126:4667"   # server3
  ]
  host_volume "grafana_data" {
    path      = "/opt/grafana/data"
    read_only = false
  }
}

bind_addr = "0.0.0.0"
data_dir  = "/tmp/nomad/client1"
name      = "client1"

ports {
  http = 5656
  rpc  = 5657
  serf = 5658
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