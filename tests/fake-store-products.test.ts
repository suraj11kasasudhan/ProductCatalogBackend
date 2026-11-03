import { afterEach, describe, expect, it, vi } from 'vitest';
import { FakeStoreProducts } from '../src/adapters/fake-store-products.js';

const row = {
  id: 1,
  title: 'Shirt',
  description: 'Cotton',
  category: 'clothing',
  price: 10,
  image: 'https://example.test/1.png',
  rating: { rate: 4, count: 5 },
};

describe('Fake Store adapter', () => {
  afterEach(() => vi.restoreAllMocks());

  it('logs HTTP status without exposing the upstream body', async () => {
    const log = vi.spyOn(console, 'warn').mockImplementation(() => {});
    const source = new FakeStoreProducts(
      'https://example.test',
      100,
      vi.fn().mockResolvedValue({
        ok: false,
        status: 403,
        json: async () => ({ secret: 'must not appear' }),
      }),
    );
    await expect(source.list()).rejects.toMatchObject({ status: 502 });
    expect(log).toHaveBeenCalledExactlyOnceWith('product_source_failed', {
      stage: 'http',
      status: 403,
    });
  });

  it('distinguishes timeouts without logging exception messages', async () => {
    const log = vi.spyOn(console, 'warn').mockImplementation(() => {});
    const source = new FakeStoreProducts(
      'https://example.test',
      100,
      vi
        .fn()
        .mockRejectedValue(new DOMException('private details', 'TimeoutError')),
    );
    await expect(source.list()).rejects.toMatchObject({ status: 502 });
    expect(log).toHaveBeenCalledExactlyOnceWith('product_source_failed', {
      stage: 'timeout',
    });
  });

  it('logs only allowlisted network codes', async () => {
    const log = vi.spyOn(console, 'warn').mockImplementation(() => {});
    const source = new FakeStoreProducts(
      'https://example.test',
      100,
      vi.fn().mockRejectedValue(
        new TypeError('private details', {
          cause: { code: 'ENOTFOUND', hostname: 'private host' },
        }),
      ),
    );
    await expect(source.list()).rejects.toMatchObject({ status: 502 });
    expect(log).toHaveBeenCalledExactlyOnceWith('product_source_failed', {
      stage: 'request',
      networkCode: 'ENOTFOUND',
    });
  });
  it('maps the external response and refreshes the cache after its TTL', async () => {
    let now = 0;
    const fetcher = vi
      .fn()
      .mockResolvedValue({ ok: true, json: async () => [row] });
    const source = new FakeStoreProducts(
      'https://example.test/',
      100,
      fetcher,
      () => now,
    );
    expect(await source.list()).toEqual([
      {
        id: 1,
        title: 'Shirt',
        description: 'Cotton',
        category: 'clothing',
        price: 10,
        imageUrl: row.image,
        rating: { value: 4, count: 5 },
      },
    ]);
    await source.list();
    expect(fetcher).toHaveBeenCalledTimes(1);
    expect(fetcher).toHaveBeenCalledWith('https://example.test/products', {
      signal: expect.any(AbortSignal),
    });
    now = 100;
    await source.list();
    expect(fetcher).toHaveBeenCalledTimes(2);
  });
  it('coalesces simultaneous requests', async () => {
    const fetcher = vi
      .fn()
      .mockResolvedValue({ ok: true, json: async () => [row] });
    const source = new FakeStoreProducts('https://example.test', 100, fetcher);
    await Promise.all([source.list(), source.list(), source.list()]);
    expect(fetcher).toHaveBeenCalledTimes(1);
  });
  it.each([
    { ok: false, json: async () => [] },
    { ok: true, json: async () => [{ ...row, price: 'wrong' }] },
    { ok: true, json: async () => [row, row] },
  ])(
    'rejects upstream HTTP and schema failures without caching them',
    async (response) => {
      const fetcher = vi
        .fn()
        .mockResolvedValueOnce(response)
        .mockResolvedValueOnce({ ok: true, json: async () => [row] });
      const source = new FakeStoreProducts(
        'https://example.test',
        100,
        fetcher,
      );
      await expect(source.list()).rejects.toMatchObject({
        status: 502,
        code: 'PRODUCT_SOURCE_UNAVAILABLE',
      });
      expect(await source.list()).toHaveLength(1);
    },
  );
  it('handles a timeout without leaking upstream details', async () => {
    const source = new FakeStoreProducts(
      'https://example.test',
      100,
      vi.fn().mockRejectedValue(new DOMException('secret URL', 'TimeoutError')),
    );
    await expect(source.list()).rejects.toMatchObject({
      status: 502,
      code: 'PRODUCT_SOURCE_UNAVAILABLE',
    });
  });
});
