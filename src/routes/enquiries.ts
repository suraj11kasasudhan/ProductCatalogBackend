import { Router } from 'express';
import { z } from 'zod';
import type { EnquiryService } from '../services/enquiry-service.js';

const singleLine = z.string().trim().min(1).max(100).refine(value => !/[\r\n]/.test(value));
const enquirySchema = z.object({
  productId: z.number().int().positive().safe(), name: singleLine,
  email: z.string().trim().max(254).pipe(z.email()),
  phone: z.string().trim().min(3).max(30).regex(/^[+()\d .-]+$/).optional(),
  message: z.string().trim().min(1).max(5000),
}).strict();

export function enquiryRouter(enquiries: EnquiryService) {
  const router = Router();
  router.post('/', async (req, res) => {
    const input = enquirySchema.parse(req.body);
    await enquiries.submit(input);
    res.status(200).json({ message: 'Thank you. Your enquiry has been sent to our sales team.' });
  });
  return router;
}
