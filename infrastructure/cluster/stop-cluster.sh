#!/bin/bash

echo "🛑 Encerrando todos os agentes Nomad locais..."

# Encontra todos os processos nomad agent (exceto o próprio grep)
PIDS=$(pgrep -f "nomad agent")

if [ -z "$PIDS" ]; then
  echo "⚠️  Nenhum processo do Nomad Agent em execução encontrado."
else
  echo "🔍 Encontrado(s): $PIDS"
  echo "⏹️  Encerrando..."
  kill $PIDS
  echo "✅ Todos os agentes foram encerrados."
fi