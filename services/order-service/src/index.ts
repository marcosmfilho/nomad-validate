import express from 'express';
import amqplib from 'amqplib';

const app = express();
app.use(express.json());

const RABBITMQ_URL = process.env.RABBITMQ_URL || 'amqp://rabbitmq:5672';
let channel: amqplib.Channel;

async function wait(ms: number) {
  return new Promise((res) => setTimeout(res, ms));
}

async function initRabbitMQ() {
  const maxRetries = 10;
  let attempt = 0;

  while (attempt < maxRetries) {
    try {
      const conn = await amqplib.connect(RABBITMQ_URL);
      channel = await conn.createChannel();
      await channel.assertExchange('orders', 'fanout', { durable: false });
      console.log('✅ Connected to RabbitMQ');
      return;
    } catch (err) {
      attempt++;
      console.error(`❌ Failed to connect to RabbitMQ (attempt ${attempt})`);
      await wait(2000); // espera 2 segundos antes de tentar novamente
    }
  }

  throw new Error('❌ Failed to connect to RabbitMQ after max retries');
}

app.get('/health', (_req, res) => res.send('ok'));

app.post('/order', async (req, res) => {
  const order = {
    id: Math.random().toString(36).substring(2),
    ...req.body,
  };

  try {
    channel.publish('orders', '', Buffer.from(JSON.stringify(order)));
    res.status(201).json({ message: 'Order created', order });
  } catch (err) {
    console.error('❌ Failed to publish order', err);
    res.status(500).json({ error: 'Failed to process order' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, async () => {
  console.log(`Order Service listening on port ${PORT}`);
  await initRabbitMQ();
});