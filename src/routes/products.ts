import { Router } from 'express';
import { z } from 'zod';
import type { CatalogueService } from '../services/catalogue-service.js';

export function productRouter(catalogue: CatalogueService) {
  const router = Router();
  router.get('/featured', async (_req, res) => { res.json({ products: await catalogue.featured() }); });
  router.get('/', async (req, res) => {
    const filters = z.object({ category: z.string().trim().min(1).max(100).optional(), q: z.string().trim().max(200).optional() }).strict().parse(req.query);
    res.json({ products: await catalogue.list(filters) });
  });
  router.get('/:id', async (req, res) => {
    const id = z.string().regex(/^[1-9]\d*$/).transform(Number).pipe(z.number().safe()).parse(req.params.id);
    res.json({ product: await catalogue.get(id) });
  });
  return router;
}
