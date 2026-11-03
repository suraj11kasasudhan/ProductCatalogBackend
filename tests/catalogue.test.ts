import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { setup } from './helpers.js';
import { AppError } from '../src/errors.js';

describe('catalogue HTTP API', () => {
  it('returns precisely the configured five featured products in selection order', async () => {
    const res = await request(setup().app)
      .get('/api/products/featured')
      .expect(200);
    expect(res.body.products.map((p: { id: number }) => p.id)).toEqual([
      5, 4, 3, 2, 1,
    ]);
  });
  it('groups category featured and additional products without duplicates', async () => {
    const res = await request(setup().app)
      .get('/api/categories/clothing/products')
      .expect(200);
    expect(res.body.featured.map((p: { id: number }) => p.id)).toEqual([
      3, 2, 1,
    ]);
    expect(res.body.products.map((p: { id: number }) => p.id)).toEqual([6]);
  });
  it('searches title and description case-insensitively and combines category filters', async () => {
    const { app } = setup();
    const res = await request(app)
      .get('/api/products')
      .query({ q: '  COTTON  ', category: 'clothing' })
      .expect(200);
    expect(res.body.products.map((p: { id: number }) => p.id)).toEqual([1, 6]);
    expect(
      (await request(app).get('/api/products?q=absent').expect(200)).body
        .products,
    ).toEqual([]);
    expect(
      (await request(app).get('/api/products?q=').expect(200)).body.products,
    ).toHaveLength(7);
  });
  it('does not match a search phrase that only spans two separate fields', async () => {
    const response = await request(setup().app)
      .get('/api/products')
      .query({ q: 'shirt Description' })
      .expect(200);
    expect(response.body.products).toEqual([]);
  });

  it('returns categories and product details in the backend contract', async () => {
    const { app } = setup();
    expect(
      (await request(app).get('/api/categories').expect(200)).body.categories,
    ).toEqual(['clothing', 'jewellery']);
    const res = await request(app).get('/api/products/1').expect(200);
    expect(res.body.product).toMatchObject({
      id: 1,
      title: 'Cotton Shirt',
      price: 12.5,
      imageUrl: 'https://example.test/product.png',
    });
  });
  it('distinguishes invalid IDs, missing products and missing categories', async () => {
    const { app } = setup();
    await request(app).get('/api/products/nope').expect(400);
    await request(app).get('/api/products/1.5').expect(400);
    await request(app).get('/api/products/999').expect(404);
    await request(app).get('/api/categories/missing/products').expect(404);
    await request(app).get('/api/products?q[x]=foo').expect(400);
  });
  it('does not silently return fewer than five featured products', async () => {
    const { app, source } = setup();
    source.list.mockResolvedValue([]);
    expect(
      (await request(app).get('/api/products/featured').expect(503)).body.error
        .code,
    ).toBe('FEATURED_PRODUCTS_UNAVAILABLE');
  });
  it('returns a safe upstream failure and a dependency-independent health response', async () => {
    const { app, source } = setup();
    source.list.mockRejectedValue(
      new AppError(
        502,
        'PRODUCT_SOURCE_UNAVAILABLE',
        'Temporarily unavailable.',
      ),
    );
    await request(app).get('/api/health').expect(200, { status: 'ok' });
    expect(
      (await request(app).get('/api/products').expect(502)).body.error.code,
    ).toBe('PRODUCT_SOURCE_UNAVAILABLE');
  });
});
