import { afterEach, describe, expect, it, vi } from 'vitest';
import { DummyJSONProducts } from '../src/adapters/dummy-json-products.js';

const row = {
  id: 1,
  title: 'Shirt',
  description: 'Cotton',
  category: 'clothing',
  price: 10,
  thumbnail: 'https://example.test/1.png',
  rating: 4,
  reviews: [{ rating: 5 }, { rating: 3 }],
};

const catalogue = (products = [row]) => ({
  products,
  total: products.length,
  skip: 0,
});

describe('DummyJSON adapter', () => {
  afterEach(() => vi.restoreAllMocks());

  it('logs HTTP status without exposing the upstream body', async () => {
    const log = vi.spyOn(console, 'warn').mockImplementation(() => {});
    const source = new DummyJSONProducts(
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
      provider: 'unidentified',
      cloudflareChallenge: false,
      responseFormat: 'other',
    });
  });

  it('identifies a Cloudflare challenge without logging cookies or response bodies', async () => {
    const log = vi.spyOn(console, 'warn').mockImplementation(() => {});
    const headers = new Headers({
      server: 'cloudflare',
      'cf-mitigated': 'challenge',
      'cf-ray': '0123456789abcdef-SIN',
      'content-type': 'text/html; charset=UTF-8',
      'set-cookie': 'private-token',
    });
    const source = new DummyJSONProducts(
      'https://example.test',
      100,
      vi
        .fn()
        .mockResolvedValue({ ok: false, status: 403, headers, json: vi.fn() }),
    );
    await expect(source.list()).rejects.toMatchObject({ status: 502 });
    expect(log).toHaveBeenCalledExactlyOnceWith('product_source_failed', {
      stage: 'http',
      status: 403,
      provider: 'cloudflare',
      cloudflareChallenge: true,
      responseFormat: 'html',
      cloudflareRay: '0123456789abcdef-SIN',
    });
  });

  it('does not mistake every Cloudflare 403 for a challenge or log arbitrary header values', async () => {
    const log = vi.spyOn(console, 'warn').mockImplementation(() => {});
    const source = new DummyJSONProducts(
      'https://example.test',
      100,
      vi.fn().mockResolvedValue({
        ok: false,
        status: 403,
        headers: new Headers({
          server: 'cloudflare',
          'cf-ray': 'private details',
          'content-type': 'application/json',
        }),
        json: vi.fn(),
      }),
    );
    await expect(source.list()).rejects.toMatchObject({ status: 502 });
    expect(log).toHaveBeenCalledExactlyOnceWith('product_source_failed', {
      stage: 'http',
      status: 403,
      provider: 'cloudflare',
      cloudflareChallenge: false,
      responseFormat: 'json',
    });
  });

  it('distinguishes timeouts without logging exception messages', async () => {
    const log = vi.spyOn(console, 'warn').mockImplementation(() => {});
    const source = new DummyJSONProducts(
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
    const source = new DummyJSONProducts(
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
      .mockResolvedValue({ ok: true, json: async () => catalogue() });
    const source = new DummyJSONProducts(
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
        imageUrl: row.thumbnail,
        rating: { value: 4, count: 2 },
      },
    ]);
    await source.list();
    expect(fetcher).toHaveBeenCalledTimes(1);
    expect(fetcher).toHaveBeenCalledWith(
      'https://example.test/products?limit=0',
      {
        signal: expect.any(AbortSignal),
      },
    );
    now = 100;
    await source.list();
    expect(fetcher).toHaveBeenCalledTimes(2);
  });
  it.each([
    { products: [row], total: 2, skip: 0 },
    { products: [row], total: 1, skip: 1 },
    { products: [row] },
    [row],
  ])('rejects incomplete or incompatible catalogues', async (payload) => {
    const source = new DummyJSONProducts(
      'https://example.test',
      100,
      vi.fn().mockResolvedValue({ ok: true, json: async () => payload }),
    );
    await expect(source.list()).rejects.toMatchObject({
      code: 'PRODUCT_SOURCE_UNAVAILABLE',
    });
  });

  it('maps products with no supplied reviews without inventing a count', async () => {
    const source = new DummyJSONProducts(
      'https://example.test',
      100,
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => catalogue([{ ...row, reviews: [] }]),
      }),
    );
    expect((await source.list())[0]?.rating).toEqual({ value: 4, count: 0 });
  });

  it('coalesces simultaneous requests', async () => {
    const fetcher = vi
      .fn()
      .mockResolvedValue({ ok: true, json: async () => catalogue() });
    const source = new DummyJSONProducts('https://example.test', 100, fetcher);
    await Promise.all([source.list(), source.list(), source.list()]);
    expect(fetcher).toHaveBeenCalledTimes(1);
  });
  it.each([
    { ok: false, json: async () => [] },
    {
      ok: true,
      json: async () => ({
        ...catalogue(),
        products: [{ ...row, price: 'wrong' }],
      }),
    },
    { ok: true, json: async () => catalogue([row, row]) },
  ])(
    'rejects upstream HTTP and schema failures without caching them',
    async (response) => {
      const fetcher = vi
        .fn()
        .mockResolvedValueOnce(response)
        .mockResolvedValueOnce({ ok: true, json: async () => catalogue() });
      const source = new DummyJSONProducts(
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
    const source = new DummyJSONProducts(
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
