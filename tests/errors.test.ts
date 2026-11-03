import request from 'supertest';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { setup } from './helpers.js';

afterEach(() => vi.restoreAllMocks());

describe('HTTP error handling', () => {
  it('keeps internal syntax errors as server errors without exposing details', async () => {
    const { app, source } = setup();
    const logger = vi.spyOn(console, 'error').mockImplementation(() => {});
    source.list.mockRejectedValue(new SyntaxError('private provider details'));
    const response = await request(app).get('/api/products').expect(500);
    expect(response.body.error.code).toBe('INTERNAL_ERROR');
    expect(response.text).not.toContain('private provider details');
    expect(logger).toHaveBeenCalledWith('Unhandled request error');
  });

  it('reports unsupported JSON character sets as client errors', async () => {
    const { app } = setup();
    const response = await request(app)
      .post('/api/enquiries')
      .set('Content-Type', 'application/json; charset=iso-8859-1')
      .send('{}')
      .expect(415);
    expect(response.body.error.code).toBe('UNSUPPORTED_CHARSET');
  });

  it('reports unsupported compression and malformed path encoding safely', async () => {
    const { app } = setup();
    const response = await request(app)
      .post('/api/enquiries')
      .set('Content-Type', 'application/json')
      .set('Content-Encoding', 'unsupported')
      .send('{}')
      .expect(415);
    expect(response.body.error.code).toBe('UNSUPPORTED_ENCODING');
    await request(app).get('/api/products/%E0%A4%A').expect(400);
  });
});
