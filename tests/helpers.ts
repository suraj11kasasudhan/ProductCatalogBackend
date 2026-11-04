import { vi } from 'vitest';
import type { Store } from 'express-rate-limit';
import { createApp } from '../src/app.js';
import { CatalogueService } from '../src/services/catalogue-service.js';
import { EnquiryService } from '../src/services/enquiry-service.js';
import type { Product } from '../src/contracts/product-source.js';

export const products: Product[] = Array.from({ length: 7 }, (_, index) => ({
  id: index + 1,
  title: index === 0 ? 'Cotton Shirt' : `Product ${index + 1}`,
  description: index === 5 ? 'Soft COTTON fabric' : 'Description',
  price: 12.5,
  imageUrl: 'https://example.test/product.png',
  category: index < 3 || index === 5 ? 'clothing' : 'jewellery',
  rating: { value: 4.5, count: 20 },
}));

export function setup(limit = 100, enquiryStore?: Store) {
  const source = { list: vi.fn().mockResolvedValue(products) };
  const mailer = { sendEnquiry: vi.fn().mockResolvedValue(undefined) };
  const catalogue = new CatalogueService(source, [5, 4, 3, 2, 1]);
  const enquiries = new EnquiryService(catalogue, mailer);
  return {
    source,
    mailer,
    app: createApp({
      catalogue,
      enquiries,
      corsOrigin: 'http://localhost:5173',
      enquiryLimit: limit,
      enquiryStore,
    }),
  };
}
