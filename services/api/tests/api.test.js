'use strict';
const request = require('supertest');
const app     = require('../src/index');
describe('Health endpoints', () => {
  it('GET /health returns 200', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
  it('GET /ready returns 200', async () => {
    const res = await request(app).get('/ready');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ready');
  });
});
describe('Items API', () => {
  it('GET /api/v1/items returns array', async () => {
    const res = await request(app).get('/api/v1/items');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.items)).toBe(true);
  });
  it('GET /api/v1/items/:id returns item', async () => {
    const res = await request(app).get('/api/v1/items/1');
    expect(res.status).toBe(200);
    expect(res.body.id).toBe(1);
  });
  it('GET /api/v1/items/abc returns 400', async () => {
    const res = await request(app).get('/api/v1/items/abc');
    expect(res.status).toBe(400);
  });
});
