#!/bin/bash

set -e

# Log da inicialização para debug
exec > >(tee -a /var/log/startup-nomad-client.log) 2>&1

echo "===> Iniciando instalação do Nomad Client..."

# Corrige repositórios quebrados (ex: bullseye-backports)
echo "===> Corrigindo repositórios quebrados..."
sed -i '/bullseye-backports/d' /etc/apt/sources.list

# Instala dependências
echo "===> Instalando dependências..."
apt-get update -y
apt-get install -y unzip curl git docker.io

# Instala Nomad
NOMAD_VERSION="1.7.5"
echo "===> Baixando Nomad versão ${NOMAD_VERSION}..."
curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip

echo "===> Extraindo e instalando Nomad..."
unzip -o nomad.zip || { echo "❌ Falha ao descompactar o Nomad"; exit 1; }
mv nomad /usr/local/bin/ || { echo "❌ Falha ao mover o binário do Nomad"; exit 1; }
chmod +x /usr/local/bin/nomad

# Validação
if ! command -v nomad >/dev/null 2>&1; then
  echo "❌ Nomad não está no PATH. A instalação falhou."
  exit 1
else
  echo "✅ Nomad instalado com sucesso: $(nomad version)"
fi

# Cria diretórios necessários
echo "===> Criando diretórios..."
mkdir -p /etc/nomad.d /opt/nomad
chmod a+w /etc/nomad.d /opt/nomad

mkdir -p /opt/grafana/data
chmod a+w /opt/grafana/data

# Configuração do Nomad Client
echo "===> Criando arquivo de configuração do Nomad Client..."
cat <<EOF > /etc/nomad.d/nomad.hcl
data_dir = "/opt/nomad"
bind_addr = "0.0.0.0"
log_level = "INFO"

client {
    enabled = true
    servers = [
        "nomad-server-1.c.nomad-validate.internal",
        "nomad-server-2.c.nomad-validate.internal",
        "nomad-server-3.c.nomad-validate.internal"
    ]
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

# Configura como serviço systemd
echo "===> Configurando Nomad como serviço systemd..."
cat <<EOF > /etc/systemd/system/nomad.service
[Unit]
Description=Nomad Client
After=network.target

[Service]
ExecStart=/usr/local/bin/nomad agent -config=/etc/nomad.d
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable nomad
systemctl start nomad

echo "✅ Nomad Client iniciado com sucesso!"