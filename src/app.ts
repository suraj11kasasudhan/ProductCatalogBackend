import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { rateLimit, type Store } from 'express-rate-limit';
import type { CatalogueService } from './services/catalogue-service.js';
import type { EnquiryService } from './services/enquiry-service.js';
import { productRouter } from './routes/products.js';
import { categoryRouter } from './routes/categories.js';
import { enquiryRouter } from './routes/enquiries.js';
import { errorHandler } from './middleware/error-handler.js';

interface AppDependencies {
  catalogue: CatalogueService;
  enquiries: EnquiryService;
  corsOrigin: string;
  enquiryLimit?: number;
  enquiryStore?: Store;
}

export function createApp(deps: AppDependencies) {
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet());
  app.use(cors({ origin: deps.corsOrigin }));
  app.use(express.json({ limit: '16kb' }));
  app.get('/api/health', (_req, res) => {
    res.json({ status: 'ok' });
  });
  app.use('/api/products', productRouter(deps.catalogue));
  app.use('/api/categories', categoryRouter(deps.catalogue));
  app.use(
    '/api/enquiries',
    rateLimit({
      windowMs: 15 * 60 * 1000,
      limit: deps.enquiryLimit ?? 10,
      store: deps.enquiryStore,
      standardHeaders: 'draft-8',
      legacyHeaders: false,
      message: {
        error: {
          code: 'RATE_LIMITED',
          message: 'Too many enquiries. Please try again later.',
        },
      },
    }),
    enquiryRouter(deps.enquiries),
  );
  app.use((_req, res) => {
    res
      .status(404)
      .json({ error: { code: 'NOT_FOUND', message: 'Route not found.' } });
  });
  app.use(errorHandler);
  return app;
}
