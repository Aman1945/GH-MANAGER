const express = require('express');
const router = express.Router();
const { getLeads, createLead, importFromEmail } = require('../controllers/leadsController');
const { protect, authorize } = require('../middleware/auth');

// GET /api/leads
router.get('/', protect, authorize('ADMIN', 'BOOKING_MANAGER'), getLeads);

// POST /api/leads
router.post('/', protect, authorize('ADMIN'), createLead);

// POST /api/leads/import-email
router.post('/import-email', protect, authorize('ADMIN'), importFromEmail);

module.exports = router;
