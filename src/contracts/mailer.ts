export interface ContactDetails {
  name: string;
  email: string;
  phone?: string;
  message: string;
}

export interface EnquiryInput extends ContactDetails {
  productId: number;
}

export interface EnquiryEmail extends ContactDetails {
  product: { id: number; title: string };
}

export interface Mailer {
  sendEnquiry(enquiry: EnquiryEmail): Promise<void>;
}
