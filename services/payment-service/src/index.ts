import express from 'express';
import amqplib from 'amqplib';

const app = express();
const PORT = process.env.PORT || 3001;
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
      await channel.assertExchange('payments', 'fanout', { durable: false });

      const q = await channel.assertQueue('', { exclusive: true });
      await channel.bindQueue(q.queue, 'orders', '');

      channel.consume(q.queue, (msg: amqplib.ConsumeMessage | null) => {
        if (msg?.content) {
          const order = JSON.parse(msg.content.toString());
          console.log('🧾 Processing payment for order:', order.id);

          const payment = {
            orderId: order.id,
            status: 'paid',
            timestamp: new Date().toISOString(),
          };

          channel.publish('payments', '', Buffer.from(JSON.stringify(payment)));
          console.log('💸 Payment published:', payment);
        }
      }, { noAck: true });

      console.log('✅ Connected to RabbitMQ and consuming from orders');
      return;
    } catch (err) {
      attempt++;
      console.error(`❌ Failed to connect to RabbitMQ (attempt ${attempt})`);
      await wait(2000);
    }
  }

  throw new Error('❌ Could not connect to RabbitMQ');
}

app.get('/health', (_req, res) => res.send('ok'));

app.listen(PORT, async () => {
  console.log(`Payment Service listening on port ${PORT}`);
  await initRabbitMQ();
});