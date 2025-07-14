server {
  enabled = true
  bootstrap_expect = 3
  server_join {
    retry_join = ["192.168.0.126:4672"]
  }
}

bind_addr = "0.0.0.0"
data_dir  = "/tmp/nomad/server3"
name      = "server3"

ports {
  http = 4666
  rpc  = 4667
  serf = 4668
}

advertise {
  http = "192.168.0.126"
  rpc  = "192.168.0.126"
  serf = "192.168.0.126"
}