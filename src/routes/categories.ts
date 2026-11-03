import { Router } from 'express';
import { z } from 'zod';
import type { CatalogueService } from '../services/catalogue-service.js';

export function categoryRouter(catalogue: CatalogueService) {
  const router = Router();
  router.get('/', async (_req, res) => { res.json({ categories: await catalogue.categories() }); });
  router.get('/:category/products', async (req, res) => {
    const category = z.string().min(1).max(100).parse(req.params.category);
    res.json(await catalogue.category(category));
  });
  return router;
}
