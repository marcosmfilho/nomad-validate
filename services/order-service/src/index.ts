import express from 'express';
import amqplib from 'amqplib';

const app = express();
const PORT = process.env.PORT || 3000;
const RABBITMQ_URL = process.env.RABBITMQ_URL || 'amqp://rabbitmq:5672';

let channel: amqplib.Channel | null = null;

async function wait(ms: number) {
  return new Promise((res) => setTimeout(res, ms));
}

async function connectRabbitMQ() {
  let attempt = 0;

  while (true) {
    try {
      const connection = await amqplib.connect(RABBITMQ_URL);
      channel = await connection.createChannel();

      await channel.assertExchange('orders', 'fanout', { durable: false });

      console.log('✅ Connected to RabbitMQ');

      connection.on('close', () => {
        console.warn('⚠️ RabbitMQ connection closed. Reconnecting...');
        channel = null;
        connectRabbitMQ();
      });

      connection.on('error', (err) => {
        console.error('❌ RabbitMQ connection error:', err);
      });

      break;
    } catch (err) {
      attempt++;
      console.error(`❌ Failed to connect to RabbitMQ (attempt ${attempt})`);
      await wait(2000 * Math.min(attempt, 10));
    }
  }
}

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', rabbitmq: channel ? 'connected' : 'disconnected' });
});

app.post('/order', async (req, res) => {
  const order = {
    id: Math.random().toString(36).substring(2),
    ...req.body,
  };

  try {
    if (!channel) throw new Error('RabbitMQ channel unavailable');
    channel.publish('orders', '', Buffer.from(JSON.stringify(order)));
    res.status(201).json({ message: 'Order created', order });
  } catch (err) {
    console.error('❌ Failed to publish order', err);
    res.status(202).json({ message: 'Order accepted but not published yet', order });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Order Service running on port ${PORT}`);
  connectRabbitMQ(); // não bloqueante
});