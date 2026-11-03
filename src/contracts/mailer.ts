export interface EnquiryEmail {
  product: { id: number; title: string };
  name: string;
  email: string;
  phone?: string;
  message: string;
}

export interface Mailer {
  sendEnquiry(enquiry: EnquiryEmail): Promise<void>;
}
