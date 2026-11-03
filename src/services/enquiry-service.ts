import type { EnquiryInput, Mailer } from '../contracts/mailer.js';
import type { CatalogueService } from './catalogue-service.js';
import { AppError } from '../errors.js';

export class EnquiryService {
  constructor(
    private readonly catalogue: CatalogueService,
    private readonly mailer: Mailer,
  ) {}

  async submit(input: EnquiryInput) {
    const product = await this.catalogue.get(input.productId);
    try {
      await this.mailer.sendEnquiry({
        product: { id: product.id, title: product.title },
        name: input.name,
        email: input.email,
        phone: input.phone,
        message: input.message,
      });
    } catch {
      throw new AppError(
        502,
        'EMAIL_UNAVAILABLE',
        'Your enquiry could not be sent. Please try again.',
      );
    }
  }
}
