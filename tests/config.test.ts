import { expect, it } from 'vitest';
import { loadConfig } from '../src/config.js';

it('validates featured selection and SMTP configuration', () => {
  expect(loadConfig({}).FEATURED_PRODUCT_IDS).toEqual([1, 2, 3, 4, 5]);
  expect(loadConfig({ SMTP_SECURE: 'false' }).SMTP_SECURE).toBe(false);
  expect(() => loadConfig({ FEATURED_PRODUCT_IDS: '1,1,2,3,4' })).toThrow();
  expect(() => loadConfig({ SMTP_USER: 'user' })).toThrow();
  expect(() =>
    loadConfig({ PRODUCT_API_URL: 'file:///tmp/products' }),
  ).toThrow();
});
