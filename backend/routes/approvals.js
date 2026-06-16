const express = require('express');
const router = express.Router();
const { getPendingApprovals, approveLead, rejectLead } = require('../controllers/approvalsController');
const { protect, authorize } = require('../middleware/auth');

// GET /api/approvals/pending
router.get('/pending', protect, authorize('BOOKING_MANAGER'), getPendingApprovals);

// POST /api/approvals/:id/approve
router.post('/:id/approve', protect, authorize('BOOKING_MANAGER'), approveLead);

// POST /api/approvals/:id/reject
router.post('/:id/reject', protect, authorize('BOOKING_MANAGER'), rejectLead);

module.exports = router;
