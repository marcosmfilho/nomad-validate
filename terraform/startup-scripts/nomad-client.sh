#!/bin/bash

set -e

# Instala dependências
apt-get update -y
apt-get install -y unzip curl git docker.io

# Instala Nomad
NOMAD_VERSION="1.7.5"
curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip
unzip nomad.zip -d /usr/local/bin/
rm nomad.zip

# Cria diretórios
mkdir -p /etc/nomad.d /opt/nomad
chmod a+w /etc/nomad.d /opt/nomad

mkdir -p /opt/grafana/data
chmod a+w /opt/grafana/data

# Configuração do Nomad Client
cat <<EOF > /etc/nomad.d/nomad.hcl
data_dir = "/opt/nomad"
bind_addr = "0.0.0.0"
log_level = "INFO"

client {
    enabled = true
    servers = ["nomad-server-1", "nomad-server-2", "nomad-server-3"]
    host_volume "grafana_data" {
        path      = "/opt/grafana/data"
        read_only = false
    }
}

telemetry {
    prometheus_metrics = true
    publish_allocation_metrics = true
    publish_node_metrics = true
}

plugin "docker" {
    config {
        allow_privileged = true
        volumes {
            enabled = true
        }
    }
}
EOF

# Inicia o agente Nomad em background
nomad agent -config=/etc/nomad.d/nomad.hcl > /var/log/nomad.log 2>&1 &