# 🧩 Sistema de Pedidos Distribuído com HashiCorp Nomad + RabbitMQ

Este projeto simula um sistema interno de pedidos composto por microserviços orquestrados via **HashiCorp Nomad**, comunicando-se através de **RabbitMQ**, com **monitoramento via Prometheus/Grafana** e **testes de carga com Locust**.

---

## 🧱 Arquitetura Geral

```
Usuário → Traefik → /order → order-service  
                            ↓  
                        RabbitMQ  
                            ↓  
          payment-service (consumer)  
                            ↓  
                        RabbitMQ  
                            ↓  
       notification-service (consumer)
```

Todos os serviços se comunicam via **publish/subscribe**, usando **exchanges do RabbitMQ**.

---

## 🚀 Serviços

| Serviço               | Descrição                                                                 |
|------------------------|--------------------------------------------------------------------------|
| `order-service`        | Cria pedidos, publica na exchange `orders`                               |
| `payment-service`      | Escuta `orders`, simula pagamento e publica em `payments`                |
| `notification-service` | Escuta `payments`, loga a confirmação do pagamento                       |
| `rabbitmq`             | Broker AMQP + UI para inspecionar exchanges, filas e mensagens           |
| `prometheus`           | Coleta métricas de cada serviço via endpoint `/health` ou `/metrics`     |
| `grafana`              | Visualiza métricas e dashboards                                          |
| `traefik`              | API Gateway e roteador HTTP com base nas tags de serviço via Consul      |
| `locust`               | Geração de carga para simular pedidos                                    |

---

## 🔗 Endpoints (via Traefik)

| Rota                  | Serviço               | Porta interna |
|-----------------------|------------------------|---------------|
| `/order`              | order-service          | 3000          |
| `/payment`            | payment-service        | 3001          |
| `/notify`             | notification-service   | 3002          |
| `/prometheus`         | prometheus             | 9090          |
| `/grafana`            | grafana                | 3000          |

---

## ⚙️ Como executar

### ✅ Opção 1 – Ambiente local com Docker Compose

```bash
docker compose build
docker compose up
```

Acessos locais:

- 🧾 **Order API**: http://localhost:3000/order  
- 🐰 **RabbitMQ UI**: http://localhost:15672 (user: `guest`, pass: `guest`)  
- 📈 **Locust UI**: http://localhost:8089  

---

### 🧵 Opção 2 – Orquestração com HashiCorp Nomad

Requer: `nomad`, `consul`, `vault` e `docker` instalados.

1. Submeter os jobs com:

```bash
nomad run infrastructure/nomad/<job>.nomad.hcl
```

Exemplo:

```bash
nomad run infrastructure/nomad/traefik.nomad.hcl
nomad run infrastructure/nomad/rabbitmq.nomad.hcl
nomad run infrastructure/nomad/order-service.nomad.hcl
```

2. Acesse os serviços via o endereço do **Traefik** (porta 80)

---

## 📊 Monitoramento

- `prometheus.yml`: scrapes dos serviços via Consul  
- Todos os serviços expõem `/health`  
- Grafana acessível via `/grafana`  
- Dashboards básicos: latência, uso de CPU/memória, tempo de resposta  

---

## 🔬 Testes de carga com Locust

1. Rode o Locust localmente:

```bash
cd locust
locust -f locustfile.py --host http://localhost:3000
```

2. Acesse a UI: http://localhost:8089

Parâmetros sugeridos:

- 100 usuários, 10 por segundo  
- Requisições POST para `/order`  
- Geração de pedidos com dados aleatórios  

---

## 📦 Estrutura do Projeto

```
.
├── docker-compose.yml
├── locust/
│   └── locustfile.py
├── services/
│   ├── order-service/
│   ├── payment-service/
│   └── notification-service/
├── infrastructure/
│   ├── nomad/
│   │   └── *.nomad.hcl
│   ├── prometheus/
│   │   └── prometheus.yml
│   └── grafana/
│       └── dashboards.json (opcional)
```

---

## 🔒 Vault e Consul (em andamento)

- Vault pode ser usado para injetar segredos como JWT, DSN, etc.  
- Consul é usado para descoberta de serviços via DNS (`*.service.consul`)  
- Traefik usa Consul Catalog para definir rotas com base nas tags dos serviços  

---

## 📎 Extras

- Cada serviço pode ser individualmente testado com `curl`, Postman ou Locust  
- As métricas podem ser usadas como figuras no artigo técnico  
- Todo o sistema é leve, replicável e simula produção real com foco em resiliência  

---

## 👨‍🔬 Autor

**Marcos Antonio Maciel Soares Filho**  
Projeto acadêmico-técnico para estudo de Nomad como orquestrador de alta eficiência.
