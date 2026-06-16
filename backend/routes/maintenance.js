const express = require('express');
const router = express.Router();
const {
  getMaintenanceRequests,
  createMaintenanceRequest,
  resolveMaintenanceRequest
} = require('../controllers/maintenanceController');
const { protect, authorize } = require('../middleware/auth');

// GET /api/maintenance — admin/BM see all, GH manager sees own guest house
router.get('/', protect, authorize('ADMIN', 'BOOKING_MANAGER', 'GH_MANAGER'), getMaintenanceRequests);

// POST /api/maintenance — GH manager reports an issue
router.post('/', protect, authorize('GH_MANAGER'), createMaintenanceRequest);

// PATCH /api/maintenance/:id/resolve — admin/BM resolves it
router.patch('/:id/resolve', protect, authorize('ADMIN', 'BOOKING_MANAGER'), resolveMaintenanceRequest);

module.exports = router;
