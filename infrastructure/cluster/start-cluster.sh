#!/bin/bash

echo "Iniciando Nomad Cluster local..."
echo ""

# Caminho base do cluster
BASE_DIR="$(dirname "$0")"

# Inicia servidores em background
echo "➡️  Iniciando servidores..."
nomad agent -config="$BASE_DIR/server1.hcl" > /tmp/nomad-server1.log 2>&1 &
nomad agent -config="$BASE_DIR/server2.hcl" > /tmp/nomad-server2.log 2>&1 &
nomad agent -config="$BASE_DIR/server3.hcl" > /tmp/nomad-server3.log 2>&1 &

# Inicia clients em background
echo "➡️  Iniciando clients..."
nomad agent -config="$BASE_DIR/client1.hcl" > /tmp/nomad-client1.log 2>&1 &
nomad agent -config="$BASE_DIR/client2.hcl" > /tmp/nomad-client2.log 2>&1 &

echo ""
echo "✅ Todos os agentes foram iniciados em background."
echo "🌐 Acesse a interface: http://localhost:4646"
echo "📄 Logs disponíveis em: /tmp/nomad-*.log"