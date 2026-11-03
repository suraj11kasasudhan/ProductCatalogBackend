import { z } from 'zod';
import type { Product, ProductSource } from '../contracts/product-source.js';
import { AppError } from '../errors.js';

const upstreamProduct = z.object({
  id: z.number().int().positive(),
  title: z.string().min(1),
  description: z.string(),
  price: z.number().nonnegative(),
  image: z.url(),
  category: z.string().min(1),
  rating: z.object({
    rate: z.number().min(0).max(5),
    count: z.number().int().nonnegative(),
  }),
});

type Fetcher = (
  url: string,
  init: { signal: AbortSignal },
) => Promise<{ ok: boolean; status?: number; json(): Promise<unknown> }>;

export class FakeStoreProducts implements ProductSource {
  private cache?: { products: Product[]; expiresAt: number };
  private pending?: Promise<Product[]>;

  constructor(
    private readonly baseUrl: string,
    private readonly ttlMs = 60000,
    private readonly fetcher: Fetcher = fetch,
    private readonly now: () => number = Date.now,
  ) {}

  async list(): Promise<Product[]> {
    if (this.cache && this.cache.expiresAt > this.now())
      return this.cache.products;
    if (this.pending) return this.pending;
    this.pending = this.load();
    try {
      return await this.pending;
    } finally {
      this.pending = undefined;
    }
  }

  private async load(): Promise<Product[]> {
    let stage = 'request';
    let status: number | undefined;
    try {
      const response = await this.fetcher(
        `${this.baseUrl.replace(/\/$/, '')}/products`,
        { signal: AbortSignal.timeout(5000) },
      );
      status = response.status;
      stage = 'http';
      if (!response.ok) throw new Error('Upstream HTTP error');
      stage = 'json';
      const payload = await response.json();
      stage = 'schema';
      const rows = z.array(upstreamProduct).parse(payload);
      stage = 'duplicate_ids';
      if (new Set(rows.map((row) => row.id)).size !== rows.length)
        throw new Error('Duplicate product IDs');
      const products = rows.map((row) => ({
        id: row.id,
        title: row.title,
        description: row.description,
        price: row.price,
        imageUrl: row.image,
        category: row.category,
        rating: { value: row.rating.rate, count: row.rating.count },
      }));
      this.cache = { products, expiresAt: this.now() + this.ttlMs };
      return products;
    } catch (error) {
      // Log only controlled categories and numeric status. Never log response
      // bodies, URLs, credentials, or upstream exception messages.
      const timeout = error instanceof Error && error.name === 'TimeoutError';
      const cause = error instanceof Error ? error.cause : undefined;
      const code =
        cause && typeof cause === 'object' && 'code' in cause
          ? cause.code
          : undefined;
      const networkCode =
        typeof code === 'string' &&
        [
          'ENOTFOUND',
          'EAI_AGAIN',
          'ECONNREFUSED',
          'ECONNRESET',
          'ETIMEDOUT',
          'UND_ERR_CONNECT_TIMEOUT',
          'CERT_HAS_EXPIRED',
          'UNABLE_TO_VERIFY_LEAF_SIGNATURE',
        ].includes(code)
          ? code
          : undefined;
      console.warn('product_source_failed', {
        stage: timeout ? 'timeout' : stage,
        ...(Number.isInteger(status) ? { status } : {}),
        ...(networkCode ? { networkCode } : {}),
      });
      throw new AppError(
        502,
        'PRODUCT_SOURCE_UNAVAILABLE',
        'Product catalogue is temporarily unavailable. Please try again.',
      );
    }
  }
}
