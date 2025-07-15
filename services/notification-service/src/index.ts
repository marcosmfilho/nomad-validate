import express from 'express';
import amqplib from 'amqplib';

const app = express();
const PORT = process.env.PORT || 3002;
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

      await channel.assertExchange('payments', 'fanout', { durable: false });

      const q = await channel.assertQueue('', { exclusive: true });
      await channel.bindQueue(q.queue, 'payments', '');

      channel.consume(q.queue, (msg: amqplib.ConsumeMessage | null) => {
        if (msg?.content) {
          const payment = JSON.parse(msg.content.toString());
          console.log('📢 Notification: Payment confirmed for order', payment.orderId);
        }
      }, { noAck: true });

      console.log('✅ Connected to RabbitMQ and consuming from payments');

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

app.listen(PORT, () => {
  console.log(`🚀 Notification Service listening on port ${PORT}`);
  connectRabbitMQ();
});