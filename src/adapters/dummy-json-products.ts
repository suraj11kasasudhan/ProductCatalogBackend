import { z } from 'zod';
import type { Product, ProductSource } from '../contracts/product-source.js';
import { AppError } from '../errors.js';

const upstreamProduct = z.object({
  id: z.number().int().positive(),
  title: z.string().min(1),
  description: z.string(),
  price: z.number().nonnegative(),
  thumbnail: z.url(),
  category: z.string().min(1),
  rating: z.number().min(0).max(5),
  reviews: z.array(z.object({ rating: z.number().min(0).max(5) })),
});

const upstreamCatalogue = z.object({
  products: z.array(upstreamProduct),
  total: z.number().int().nonnegative(),
  skip: z.number().int().nonnegative(),
});

type Fetcher = (
  url: string,
  init: { signal: AbortSignal },
) => Promise<{
  ok: boolean;
  status?: number;
  headers?: { get(name: string): string | null };
  json(): Promise<unknown>;
}>;

export class DummyJSONProducts implements ProductSource {
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
    let upstream: Record<string, string | boolean> = {};
    try {
      const response = await this.fetcher(
        `${this.baseUrl.replace(/\/$/, '')}/products?limit=0`,
        { signal: AbortSignal.timeout(5000) },
      );
      status = response.status;
      if (!response.ok) {
        const server = response.headers?.get('server')?.toLowerCase();
        const contentType = response.headers
          ?.get('content-type')
          ?.toLowerCase();
        const ray = response.headers?.get('cf-ray');
        upstream = {
          provider: server?.includes('cloudflare')
            ? 'cloudflare'
            : 'unidentified',
          cloudflareChallenge:
            response.headers?.get('cf-mitigated') === 'challenge',
          responseFormat: contentType?.includes('text/html')
            ? 'html'
            : contentType?.includes('application/json')
              ? 'json'
              : 'other',
          // Cloudflare's bounded trace ID helps its operator locate the refusal.
          ...(ray && /^[a-f0-9]{16,32}-[A-Z]{3}$/i.test(ray)
            ? { cloudflareRay: ray }
            : {}),
        };
      }
      stage = 'http';
      if (!response.ok) throw new Error('Upstream HTTP error');
      stage = 'json';
      const payload = await response.json();
      stage = 'schema';
      const catalogue = upstreamCatalogue.parse(payload);
      // Search and category grouping must cover the full upstream catalogue.
      if (catalogue.skip !== 0 || catalogue.products.length !== catalogue.total)
        throw new Error('Incomplete upstream catalogue');
      const rows = catalogue.products;
      stage = 'duplicate_ids';
      if (new Set(rows.map((row) => row.id)).size !== rows.length)
        throw new Error('Duplicate product IDs');
      const products = rows.map((row) => ({
        id: row.id,
        title: row.title,
        description: row.description,
        price: row.price,
        imageUrl: row.thumbnail,
        category: row.category,
        rating: { value: row.rating, count: row.reviews.length },
      }));
      this.cache = { products, expiresAt: this.now() + this.ttlMs };
      return products;
    } catch (error) {
      // Log controlled categories, numeric status, and a validated trace ID. Never log response
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
        ...upstream,
      });
      throw new AppError(
        502,
        'PRODUCT_SOURCE_UNAVAILABLE',
        'Product catalogue is temporarily unavailable. Please try again.',
      );
    }
  }
}
