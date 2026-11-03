import { createServer } from 'node:http';
import { once } from 'node:events';
import { expect, it, vi } from 'vitest';
import request from 'supertest';
import { DummyJSONProducts } from '../src/adapters/dummy-json-products.js';
import { CatalogueService } from '../src/services/catalogue-service.js';
import { EnquiryService } from '../src/services/enquiry-service.js';
import { createApp } from '../src/app.js';

it('serves the existing iOS contract through the real DummyJSON HTTP adapter', async () => {
  const paths: string[] = [];
  const upstream = createServer((req, res) => {
    paths.push(req.url ?? '');
    res.setHeader('Content-Type', 'application/json');
    res.end(
      JSON.stringify({
        products: Array.from({ length: 6 }, (_, index) => ({
          id: index + 1,
          title: `Mascara ${index + 1}`,
          description: 'Daily beauty',
          price: 10,
          thumbnail: 'https://example.test/product.png',
          category: 'beauty',
          rating: 4.5,
          reviews: [{ rating: 5 }],
        })),
        total: 6,
        skip: 0,
        limit: 6,
      }),
    );
  });
  upstream.listen(0, '127.0.0.1');
  await once(upstream, 'listening');
  try {
    const address = upstream.address();
    if (!address || typeof address === 'string')
      throw new Error('Missing listener');
    const source = new DummyJSONProducts(`http://127.0.0.1:${address.port}`);
    const catalogue = new CatalogueService(source, [1, 2, 3, 4, 5]);
    const mailer = { sendEnquiry: vi.fn().mockResolvedValue(undefined) };
    const app = createApp({
      catalogue,
      enquiries: new EnquiryService(catalogue, mailer),
      corsOrigin: 'http://localhost:5173',
    });
    const featured = await request(app)
      .get('/api/products/featured')
      .expect(200);
    expect(featured.body.products).toHaveLength(5);
    expect(featured.body.products[0]).toEqual({
      id: 1,
      title: 'Mascara 1',
      description: 'Daily beauty',
      price: 10,
      imageUrl: 'https://example.test/product.png',
      category: 'beauty',
      rating: { value: 4.5, count: 1 },
    });
    const categories = await request(app).get('/api/categories').expect(200);
    expect(categories.body).toEqual({ categories: ['beauty'] });
    const groups = await request(app)
      .get('/api/categories/beauty/products')
      .expect(200);
    expect(groups.body.featured).toHaveLength(5);
    expect(groups.body.products.map((p: { id: number }) => p.id)).toEqual([6]);
    const search = await request(app)
      .get('/api/products?q=mascara%206')
      .expect(200);
    expect(search.body.products.map((p: { id: number }) => p.id)).toEqual([6]);
    const detail = await request(app).get('/api/products/6').expect(200);
    expect(detail.body.product.id).toBe(6);
    await request(app)
      .post('/api/enquiries')
      .send({
        productId: 6,
        name: 'Customer',
        email: 'customer@example.test',
        message: 'Is this available?',
      })
      .expect(200);
    expect(mailer.sendEnquiry).toHaveBeenCalledOnce();
    expect(paths).toEqual(['/products?limit=0']);
  } finally {
    upstream.closeAllConnections();
    await new Promise<void>((resolve, reject) =>
      upstream.close((error) => (error ? reject(error) : resolve())),
    );
  }
});
