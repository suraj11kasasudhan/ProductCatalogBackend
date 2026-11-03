import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { setup } from './helpers.js';

const enquiry = {
  productId: 1,
  name: 'Customer',
  email: 'customer@example.test',
  message: 'Is this available?',
};

describe('enquiries', () => {
  it('sends verified product details to the mail adapter before confirming success', async () => {
    const { app, mailer } = setup();
    const res = await request(app)
      .post('/api/enquiries')
      .send(enquiry)
      .expect(200);
    expect(res.body.message).toContain('Thank you');
    expect(mailer.sendEnquiry).toHaveBeenCalledWith(
      expect.objectContaining({
        product: { id: 1, title: 'Cotton Shirt' },
        email: enquiry.email,
        message: enquiry.message,
      }),
    );
  });
  it.each([
    { ...enquiry, email: 'invalid' },
    { ...enquiry, name: ' ' },
    { ...enquiry, name: 'Header\r\nInjection' },
    { ...enquiry, message: '' },
    { ...enquiry, message: 'x'.repeat(5001) },
    { ...enquiry, phone: 'bad phone' },
    { ...enquiry, productId: '1' },
    { ...enquiry, to: 'attacker@example.test' },
  ])('rejects invalid input without sending email: %j', async (input) => {
    const { app, mailer } = setup();
    await request(app).post('/api/enquiries').send(input).expect(400);
    expect(mailer.sendEnquiry).not.toHaveBeenCalled();
  });
  it('rejects nonexistent products before sending', async () => {
    const { app, mailer } = setup();
    await request(app)
      .post('/api/enquiries')
      .send({ ...enquiry, productId: 999 })
      .expect(404);
    expect(mailer.sendEnquiry).not.toHaveBeenCalled();
  });
  it('does not thank the customer when email delivery fails', async () => {
    const { app, mailer } = setup();
    mailer.sendEnquiry.mockRejectedValue(
      new Error('sensitive SMTP information'),
    );
    const res = await request(app)
      .post('/api/enquiries')
      .send(enquiry)
      .expect(502);
    expect(res.body.error.code).toBe('EMAIL_UNAVAILABLE');
    expect(res.text).not.toContain('sensitive');
  });
  it('rate limits repeated submissions', async () => {
    const { app, mailer } = setup(1);
    await request(app).post('/api/enquiries').send(enquiry).expect(200);
    await request(app).post('/api/enquiries').send(enquiry).expect(429);
    expect(mailer.sendEnquiry).toHaveBeenCalledTimes(1);
  });
  it('handles malformed JSON and oversized bodies', async () => {
    const { app } = setup();
    await request(app)
      .post('/api/enquiries')
      .set('Content-Type', 'application/json')
      .send('{')
      .expect(400);
    await request(app)
      .post('/api/enquiries')
      .send({ ...enquiry, message: 'x'.repeat(20000) })
      .expect(413);
  });
});
