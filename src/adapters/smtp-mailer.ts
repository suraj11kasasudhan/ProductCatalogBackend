import nodemailer from 'nodemailer';
import type { Config } from '../config.js';
import type { EnquiryEmail, Mailer } from '../contracts/mailer.js';

export class SmtpMailer implements Mailer {
  private transport;
  constructor(private config: Config) {
    this.transport = nodemailer.createTransport({
      host: config.SMTP_HOST, port: config.SMTP_PORT, secure: config.SMTP_SECURE,
      auth: config.SMTP_USER ? { user: config.SMTP_USER, pass: config.SMTP_PASS } : undefined,
      connectionTimeout: 5000, greetingTimeout: 5000, socketTimeout: 10000,
    });
  }

  async sendEnquiry(enquiry: EnquiryEmail): Promise<void> {
    const result = await this.transport.sendMail({
      from: this.config.MAIL_FROM, to: this.config.SALES_EMAIL, replyTo: enquiry.email,
      subject: `Product enquiry #${enquiry.product.id}`,
      text: [
        `Product: ${enquiry.product.title} (#${enquiry.product.id})`,
        `Name: ${enquiry.name}`, `Email: ${enquiry.email}`,
        `Phone: ${enquiry.phone ?? 'Not provided'}`, '', enquiry.message,
      ].join('\n'),
    });
    if (!result.accepted.length || result.rejected.length) throw new Error('Recipient was not accepted');
  }
}
