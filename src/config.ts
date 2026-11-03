import { z } from 'zod';

const boolean = z
  .enum(['true', 'false'])
  .transform((value) => value === 'true');
const configSchema = z
  .object({
    PORT: z.coerce.number().int().min(1).max(65535).default(3000),
    PRODUCT_API_URL: z
      .url()
      .refine((value) => ['http:', 'https:'].includes(new URL(value).protocol))
      .default('https://fakestoreapi.com'),
    FEATURED_PRODUCT_IDS: z
      .string()
      .default('1,2,3,4,5')
      .transform((value) => value.split(',').map(Number))
      .refine(
        (ids) =>
          ids.length === 5 &&
          new Set(ids).size === 5 &&
          ids.every((id) => Number.isSafeInteger(id) && id > 0),
        'Provide five distinct positive product IDs',
      ),
    CACHE_TTL_MS: z.coerce.number().int().min(0).max(3600000).default(60000),
    CORS_ORIGIN: z.url().default('http://localhost:5173'),
    SMTP_HOST: z.string().min(1).default('127.0.0.1'),
    SMTP_PORT: z.coerce.number().int().min(1).max(65535).default(1025),
    SMTP_SECURE: boolean.default(false),
    SMTP_USER: z.string().min(1).optional(),
    SMTP_PASS: z.string().min(1).optional(),
    MAIL_FROM: z.email().default('catalogue@example.test'),
    SALES_EMAIL: z.email().default('sales@example.test'),
  })
  .refine(
    (value) => Boolean(value.SMTP_USER) === Boolean(value.SMTP_PASS),
    'SMTP_USER and SMTP_PASS must be supplied together',
  );

export function loadConfig(environment: NodeJS.ProcessEnv = process.env) {
  return configSchema.parse(environment);
}
export type Config = ReturnType<typeof loadConfig>;
