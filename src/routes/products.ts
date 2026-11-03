import { Router } from 'express';
import { productFiltersSchema, productIdSchema } from './schemas.js';
import type { CatalogueService } from '../services/catalogue-service.js';

export function productRouter(catalogue: CatalogueService) {
  const router = Router();
  router.get('/featured', async (_req, res) => {
    res.json({ products: await catalogue.featured() });
  });
  router.get('/', async (req, res) => {
    const filters = productFiltersSchema.parse(req.query);
    res.json({ products: await catalogue.list(filters) });
  });
  router.get('/:id', async (req, res) => {
    const id = productIdSchema.parse(req.params.id);
    res.json({ product: await catalogue.get(id) });
  });
  return router;
}
