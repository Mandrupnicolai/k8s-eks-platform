'use strict';
const { Router } = require('express');
const router = Router();
router.get('/health', (_req, res) => res.json({ status: 'ok',    timestamp: new Date().toISOString() }));
router.get('/ready',  (_req, res) => res.json({ status: 'ready', timestamp: new Date().toISOString() }));
router.get('/api/v1/items', (_req, res) => res.json({ items: [{ id: 1, name: 'Widget Alpha', status: 'active' }, { id: 2, name: 'Widget Beta', status: 'active' }] }));
router.get('/api/v1/items/:id', (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id) || id < 1) return res.status(400).json({ error: 'Invalid item ID' });
  res.json({ id, name: `Widget ${id}`, status: 'active' });
});
module.exports = router;
