#!/bin/bash

set -e

# Instala dependências básicas
apt-get update && apt-get install -y unzip curl git jq docker.io

# Instala Nomad
NOMAD_VERSION="1.7.5"
curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip
unzip nomad.zip && mv nomad /usr/local/bin/ && chmod +x /usr/local/bin/nomad

# Cria diretório de configuração
mkdir -p /etc/nomad.d
mkdir -p /opt/nomad

# IP local da interface padrão
PRIVATE_IP=$(hostname -I | awk '{print $1}')

# Recupera token do GitHub do metadata da VM
GITHUB_TOKEN=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/github_token)

# Clona o repositório privado do GitHub contendo os arquivos .hcl
git clone https://${GITHUB_TOKEN}@github.com/marcosmfilho/nomad-validate.git /opt/nomad/jobs

# Configura Nomad server
cat <<EOF > /etc/nomad.d/nomad.hcl
data_dir  = "/opt/nomad"
bind_addr = "0.0.0.0"

server {
    enabled = true
    bootstrap_expect = 3
    server_join {
        retry_join = ["nomad-server-1", "nomad-server-2", "nomad-server-3"]
        retry_max = 10
        retry_interval = "15s"
    }
}

advertise {
  http = "${PRIVATE_IP}:4646"
  rpc  = "${PRIVATE_IP}:4647"
  serf = "${PRIVATE_IP}:4648"
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

# Inicia Nomad como systemd
cat <<EOF > /etc/systemd/system/nomad.service
[Unit]
Description=Nomad Server
After=network.target

[Service]
ExecStart=/usr/local/bin/nomad agent -config=/etc/nomad.d
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl enable nomad
systemctl start nomad