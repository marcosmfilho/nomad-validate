#!/bin/bash

# Verifica se o registry local está rodando
if [ "$(docker ps -q -f name=registry)" == "" ]; then
  if [ "$(docker ps -aq -f name=registry)" == "" ]; then
    echo "🚀 Iniciando registry local na porta 5000..."
    docker run -d -p 5000:5000 --name registry registry:2
  else
    echo "🔄 Container 'registry' existe mas está parado. Reiniciando..."
    docker start registry
  fi
else
  echo "✅ Registry local já está rodando."
fi

# Lista dos serviços
SERVICES=("notification-service" "payment-service" "order-service")

# Endereço do registry local
REGISTRY="localhost:5000"

# Caminho base (ajuste se necessário)
BASE_DIR=$(pwd)

VERSION=$1

for SERVICE in "${SERVICES[@]}"; do
  echo "🔧 Buildando imagem do serviço: $SERVICE"

  cd "$BASE_DIR/$SERVICE" || {
    echo "❌ Não foi possível acessar o diretório $SERVICE"
    exit 1
  }

  # Build da imagem
  docker build -t "$SERVICE:$VERSION" .

  # Tag para o registry local
  docker tag "$SERVICE:$VERSION" "$REGISTRY/$SERVICE:$VERSION"

  # Push para o registry local
  docker push "$REGISTRY/$SERVICE:$VERSION"

  echo "✅ $SERVICE enviado para $REGISTRY"
done

echo "🎉 Todos os serviços foram buildados e enviados com sucesso!"