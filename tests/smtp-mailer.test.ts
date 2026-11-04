import { describe, expect, it, vi } from 'vitest';
import { SmtpMailer } from '../src/adapters/smtp-mailer.js';
import { loadConfig } from '../src/config.js';

const enquiry = {
  product: { id: 1, title: 'Cotton shirt' },
  name: 'Customer',
  email: 'customer@example.test',
  message: '<b>Is it available?</b>',
};

describe('SMTP mail adapter', () => {
  it('uses configured sender/recipient, customer reply-to, and plain text', async () => {
    const sendMail = vi
      .fn()
      .mockResolvedValue({ accepted: ['sales@example.test'], rejected: [] });
    await new SmtpMailer(loadConfig({}), { sendMail }).sendEnquiry(enquiry);
    const [message] = sendMail.mock.calls[0]!;
    expect(message).toMatchObject({
      from: 'catalogue@example.test',
      to: 'sales@example.test',
      replyTo: enquiry.email,
      subject: 'Product enquiry #1',
    });
    expect(message.text).toContain('Cotton shirt (#1)');
    expect(message.text).toContain(enquiry.message);
    expect(message).not.toHaveProperty('html');
  });

  it.each(['SALES@example.test', { address: 'sales@example.test' }])(
    'recognizes the configured recipient in supported SMTP response forms',
    async (recipient) => {
      const sendMail = vi
        .fn()
        .mockResolvedValue({ accepted: [recipient], rejected: [] });
      await expect(
        new SmtpMailer(loadConfig({}), { sendMail }).sendEnquiry(enquiry),
      ).resolves.toBeUndefined();
    },
  );

  it.each([
    { accepted: [], rejected: [] },
    { accepted: ['another@example.test'], rejected: [] },
    { accepted: [], rejected: ['sales@example.test'] },
    { accepted: ['another@example.test'], rejected: ['sales@example.test'] },
  ])(
    'does not confirm delivery when the recipient is not accepted: %j',
    async (result) => {
      const sendMail = vi.fn().mockResolvedValue(result);
      await expect(
        new SmtpMailer(loadConfig({}), { sendMail }).sendEnquiry(enquiry),
      ).rejects.toThrow('Recipient was not accepted');
    },
  );
});
