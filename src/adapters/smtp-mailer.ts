import nodemailer, { type SendMailOptions } from 'nodemailer';
import type { Config } from '../config.js';
import type { EnquiryEmail, Mailer } from '../contracts/mailer.js';

type SmtpConfig = Pick<
  Config,
  | 'SMTP_HOST'
  | 'SMTP_PORT'
  | 'SMTP_SECURE'
  | 'SMTP_USER'
  | 'SMTP_PASS'
  | 'MAIL_FROM'
  | 'SALES_EMAIL'
>;

// Keep SMTP results at the adapter boundary; services only depend on Mailer.
interface MailTransport {
  sendMail(options: SendMailOptions): Promise<{
    accepted: Array<string | { address: string }>;
    rejected: unknown[];
  }>;
}

export class SmtpMailer implements Mailer {
  private readonly transport: MailTransport;

  constructor(
    private readonly config: SmtpConfig,
    transport?: MailTransport,
  ) {
    this.transport =
      transport ??
      nodemailer.createTransport({
        host: config.SMTP_HOST,
        port: config.SMTP_PORT,
        secure: config.SMTP_SECURE,
        auth: config.SMTP_USER
          ? { user: config.SMTP_USER, pass: config.SMTP_PASS }
          : undefined,
        dnsTimeout: 5000,
        connectionTimeout: 5000,
        greetingTimeout: 5000,
        socketTimeout: 10000,
      });
  }

  async sendEnquiry(enquiry: EnquiryEmail): Promise<void> {
    const result = await this.transport.sendMail({
      from: this.config.MAIL_FROM,
      to: this.config.SALES_EMAIL,
      replyTo: enquiry.email,
      subject: `Product enquiry #${enquiry.product.id}`,
      text: [
        `Product: ${enquiry.product.title} (#${enquiry.product.id})`,
        `Name: ${enquiry.name}`,
        `Email: ${enquiry.email}`,
        `Phone: ${enquiry.phone ?? 'Not provided'}`,
        '',
        enquiry.message,
      ].join('\n'),
    });
    const accepted = result.accepted.some((recipient) => {
      const address =
        typeof recipient === 'string' ? recipient : recipient.address;
      return address.toLowerCase() === this.config.SALES_EMAIL.toLowerCase();
    });
    if (!accepted || result.rejected.length)
      throw new Error('Recipient was not accepted');
  }
}
