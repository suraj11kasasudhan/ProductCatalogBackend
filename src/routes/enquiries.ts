import { Router } from 'express';
import { enquirySchema } from './schemas.js';
import type { EnquiryService } from '../services/enquiry-service.js';

export function enquiryRouter(enquiries: EnquiryService) {
  const router = Router();
  router.post('/', async (req, res) => {
    const input = enquirySchema.parse(req.body);
    await enquiries.submit(input);
    res.status(200).json({
      message: 'Thank you. Your enquiry has been sent to our sales team.',
    });
  });
  return router;
}
