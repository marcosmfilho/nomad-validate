#!/bin/bash

set -e

# Log para debug
exec > >(tee -a /var/log/startup-nomad-server.log) 2>&1

echo "===> Iniciando instalação do Nomad Server..."

# Corrige repositórios quebrados (como bullseye-backports)
echo "===> Corrigindo repositórios quebrados..."
sed -i '/bullseye-backports/d' /etc/apt/sources.list

# Instala dependências
echo "===> Instalando dependências..."
apt-get update && apt-get install -y unzip curl git jq docker.io

# Instala Nomad
NOMAD_VERSION="1.7.5"
echo "===> Baixando Nomad versão ${NOMAD_VERSION}..."
curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip

echo "===> Extraindo e instalando Nomad..."
unzip -o nomad.zip
mv nomad /usr/local/bin/
chmod +x /usr/local/bin/nomad

# Validação
if ! command -v nomad >/dev/null 2>&1; then
  echo "❌ Nomad não está no PATH. A instalação falhou."
  exit 1
else
  echo "✅ Nomad instalado com sucesso: $(nomad version)"
fi

# Cria diretórios de configuração
echo "===> Criando diretórios..."
mkdir -p /etc/nomad.d /opt/nomad

# IP local (interno)
PRIVATE_IP=$(hostname -I | awk '{print $1}')

# Cria arquivo de configuração do Nomad Server
echo "===> Gerando arquivo nomad.hcl..."
cat <<EOF > /etc/nomad.d/nomad.hcl
data_dir  = "/opt/nomad"
bind_addr = "0.0.0.0"
log_level = "INFO"

server {
    enabled = true
    bootstrap_expect = 3
    server_join {
        retry_join = [
            "nomad-server-1.c.nomad-validate.internal",
            "nomad-server-2.c.nomad-validate.internal",
            "nomad-server-3.c.nomad-validate.internal"
        ]
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

# Cria serviço systemd
echo "===> Configurando Nomad como serviço systemd..."
cat <<EOF > /etc/systemd/system/nomad.service
[Unit]
Description=Nomad Server
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

# Aguarda os clients aparecerem
echo "⏳ Aguardando os Nomad Clients se registrarem..."
for i in {1..24}; do
  COUNT=$(nomad node status -json | jq length)
  if [ "$COUNT" -ge 2 ]; then
    echo "✅ $COUNT clients detectados. Prosseguindo com os jobs."
    break
  fi
  sleep 5
done

# Clona o repositório público
if [ ! -d "/opt/nomad/jobs" ]; then
  echo "📥 Clonando repositório público nomad-validate..."
  git clone https://github.com/marcosmfilho/nomad-validate.git /opt/nomad/jobs
fi

# Executa os jobs apenas no nomad-server-1
if hostname | grep -q "nomad-server-1"; then
  echo "🚀 Executando jobs .nomad.hcl no nomad-server-1..."
  cd /opt/nomad/jobs/infrastructure/nomad
  for job in *.nomad.hcl; do
    JOB_NAME=$(basename "$job" .nomad.hcl)
    if ! nomad job status "$JOB_NAME" >/dev/null 2>&1; then
      echo "➡️  Rodando job: $job"
      nomad job run "$job"
    else
      echo "ℹ️  Job $JOB_NAME já está registrado. Ignorando."
    fi
  done
else
  echo "ℹ️  Este host não é o nomad-server-1. Ignorando submissão de jobs."
fi

echo "✅ Provisionamento completo do Nomad Server e jobs finalizado com sucesso!"