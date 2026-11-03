import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { once } from 'node:events';
import request from 'supertest';
import { loadConfig } from '../src/config.js';
import { FakeStoreProducts } from '../src/adapters/fake-store-products.js';
import { SmtpMailer } from '../src/adapters/smtp-mailer.js';
import { CatalogueService } from '../src/services/catalogue-service.js';
import { EnquiryService } from '../src/services/enquiry-service.js';
import { createApp } from '../src/app.js';

// Controlled upstream data; the real HTTP adapter and SMTP transport are exercised.
const fixture = createServer((_req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(Array.from({ length: 6 }, (_, index) => ({
    id: index + 1, title: `Cotton shirt ${index + 1}`, description: 'Smoke test product',
    category: 'clothing', image: 'https://example.test/shirt.png', price: 12,
    rating: { rate: 4.5, count: 10 },
  }))));
});
fixture.listen(0, '127.0.0.1');
await once(fixture, 'listening');
try {
  const address = fixture.address();
  assert(address && typeof address !== 'string');
  const config = loadConfig({ ...process.env, FEATURED_PRODUCT_IDS: '1,2,3,4,5' });
  const catalogue = new CatalogueService(new FakeStoreProducts(`http://127.0.0.1:${address.port}`), config.FEATURED_PRODUCT_IDS);
  const app = createApp({ catalogue, enquiries: new EnquiryService(catalogue, new SmtpMailer(config)), corsOrigin: config.CORS_ORIGIN });
  const featured = await request(app).get('/api/products/featured').expect(200);
  assert.equal(featured.body.products.length, 5);
  const category = await request(app).get('/api/categories/clothing/products').expect(200);
  assert.equal(category.body.products.length, 1);
  await request(app).get('/api/products?q=cotton').expect(200);
  await request(app).get('/api/products/1').expect(200);
  const marker = `smoke-${crypto.randomUUID()}`;
  await request(app).post('/api/enquiries').send({ productId: 1, name: 'Smoke Customer', email: 'smoke@example.test', message: marker }).expect(200);
  const mailpitUrl = process.env.MAILPIT_URL ?? 'http://127.0.0.1:8025';
  const messagesResponse = await fetch(`${mailpitUrl}/api/v1/messages`);
  assert(messagesResponse.ok);
  const inbox = await messagesResponse.json() as { messages: { ID: string; Subject: string }[] };
  let delivered = false;
  for (const message of inbox.messages.filter(message => message.Subject === 'Product enquiry #1')) {
    const response = await fetch(`${mailpitUrl}/api/v1/message/${message.ID}`);
    assert(response.ok);
    const email = await response.json() as { Text: string; To: { Address: string }[]; ReplyTo: { Address: string }[] };
    if (email.Text.includes(marker)) {
      assert(email.To.some(recipient => recipient.Address === config.SALES_EMAIL));
      assert(email.ReplyTo.some(recipient => recipient.Address === 'smoke@example.test'));
      delivered = true;
      break;
    }
  }
  assert(delivered, 'Enquiry was not found in the Mailpit inbox');
  console.log('Smoke passed: catalogue HTTP adapter, API routes, and enquiry email received in Mailpit.');
} finally {
  fixture.closeAllConnections();
  fixture.close();
}
