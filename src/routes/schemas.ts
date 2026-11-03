import { z } from 'zod';

export const categoryNameSchema = z.string().trim().min(1).max(100);
export const productIdSchema = z
  .string()
  .regex(/^[1-9]\d*$/)
  .transform(Number)
  .pipe(z.number().int().positive().safe());

export const productFiltersSchema = z
  .object({
    category: categoryNameSchema.optional(),
    q: z.string().trim().max(200).optional(),
  })
  .strict();

export const enquirySchema = z
  .object({
    productId: z.number().int().positive().safe(),
    name: z
      .string()
      .trim()
      .min(1)
      .max(100)
      .refine((value) => !/[\r\n]/.test(value), 'Name must be a single line'),
    email: z.string().trim().max(254).pipe(z.email()),
    phone: z
      .string()
      .trim()
      .min(3)
      .max(30)
      .regex(/^[+()\d .-]+$/)
      .optional(),
    message: z.string().trim().min(1).max(5000),
  })
  .strict();
