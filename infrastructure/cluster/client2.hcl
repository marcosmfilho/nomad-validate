client {
  enabled = true
  servers = [
    "192.168.0.126:4671",  # server1
    "192.168.0.126:4657",  # server2
    "192.168.0.126:4667"   # server3
  ]
}

bind_addr = "0.0.0.0"
data_dir  = "/tmp/nomad/client2"
name      = "client2"

ports {
  http = 5657
  rpc  = 5658
  serf = 5659
}

advertise {
  http = "192.168.0.126"
  rpc  = "192.168.0.126"
  serf = "192.168.0.126"
}