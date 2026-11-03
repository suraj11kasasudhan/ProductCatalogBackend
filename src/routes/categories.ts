import { Router } from 'express';
import { categoryNameSchema } from './schemas.js';
import type { CatalogueService } from '../services/catalogue-service.js';

export function categoryRouter(catalogue: CatalogueService) {
  const router = Router();
  router.get('/', async (_req, res) => {
    res.json({ categories: await catalogue.categories() });
  });
  router.get('/:category/products', async (req, res) => {
    const category = categoryNameSchema.parse(req.params.category);
    res.json(await catalogue.category(category));
  });
  return router;
}
