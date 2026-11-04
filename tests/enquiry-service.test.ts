import { expect, it, vi } from 'vitest';
import { EnquiryService } from '../src/services/enquiry-service.js';
import { AppError } from '../src/errors.js';
import { products } from './helpers.js';

const input = {
  productId: 1,
  name: 'Customer',
  email: 'customer@example.test',
  message: 'Hello',
};

it('accepts a minimal product lookup and injectable mailer without HTTP or SMTP', async () => {
  const lookup = { get: vi.fn().mockResolvedValue(products[0]) };
  const mailer = { sendEnquiry: vi.fn().mockResolvedValue(undefined) };
  await new EnquiryService(lookup, mailer).submit(input);
  expect(lookup.get).toHaveBeenCalledWith(1);
  expect(mailer.sendEnquiry).toHaveBeenCalledWith({
    product: { id: 1, title: 'Cotton Shirt' },
    name: input.name,
    email: input.email,
    phone: undefined,
    message: input.message,
  });
});

it('preserves lookup failure without attempting email', async () => {
  const error = new AppError(404, 'PRODUCT_NOT_FOUND', 'Product not found.');
  const lookup = { get: vi.fn().mockRejectedValue(error) };
  const mailer = { sendEnquiry: vi.fn() };
  await expect(new EnquiryService(lookup, mailer).submit(input)).rejects.toBe(
    error,
  );
  expect(mailer.sendEnquiry).not.toHaveBeenCalled();
});

it('maps mail failures to the public error contract without exposing transport details', async () => {
  const lookup = { get: vi.fn().mockResolvedValue(products[0]) };
  const mailer = {
    sendEnquiry: vi
      .fn()
      .mockRejectedValue(new Error('private transport detail')),
  };
  await expect(
    new EnquiryService(lookup, mailer).submit(input),
  ).rejects.toMatchObject({
    status: 502,
    code: 'EMAIL_UNAVAILABLE',
    message: 'Your enquiry could not be sent. Please try again.',
  });
});
