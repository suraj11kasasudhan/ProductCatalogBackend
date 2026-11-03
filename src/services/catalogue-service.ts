import type { Product, ProductSource } from '../contracts/product-source.js';
import { AppError } from '../errors.js';

export interface ProductFilters {
  category?: string;
  q?: string;
}

export class CatalogueService {
  constructor(
    private readonly source: ProductSource,
    private readonly featuredIds: readonly number[],
  ) {}

  async list(filters: ProductFilters = {}) {
    const products = await this.source.list();
    const term = filters.q?.trim().toLowerCase();
    return products.filter(
      (product) =>
        (!filters.category || product.category === filters.category) &&
        (!term ||
          [product.title, product.description].some((text) =>
            text.toLowerCase().includes(term),
          )),
    );
  }

  private selectFeatured(products: Product[]) {
    const byId = new Map(products.map((product) => [product.id, product]));
    return this.featuredIds.map((id) => {
      const product = byId.get(id);
      if (!product)
        throw new AppError(
          503,
          'FEATURED_PRODUCTS_UNAVAILABLE',
          'Featured product selection is temporarily unavailable.',
        );
      return product;
    });
  }

  async featured() {
    return this.selectFeatured(await this.source.list());
  }

  async categories() {
    return [
      ...new Set((await this.source.list()).map((product) => product.category)),
    ].sort();
  }

  async category(category: string) {
    const all = await this.source.list();
    const products = all.filter((product) => product.category === category);
    if (!products.length)
      throw new AppError(404, 'CATEGORY_NOT_FOUND', 'Category not found.');
    return {
      featured: this.selectFeatured(all).filter(
        (product) => product.category === category,
      ),
      products: products.filter(
        (product) => !this.featuredIds.includes(product.id),
      ),
    };
  }

  async get(id: number) {
    const product = (await this.source.list()).find(
      (product) => product.id === id,
    );
    if (!product)
      throw new AppError(404, 'PRODUCT_NOT_FOUND', 'Product not found.');
    return product;
  }
}
