const express = require('express');
const router = express.Router();
const { adminDashboard, bookingManagerDashboard, ghManagerDashboard } = require('../controllers/dashboardController');
const { protect, authorize } = require('../middleware/auth');

// GET /api/dashboard/admin
router.get('/admin', protect, authorize('ADMIN'), adminDashboard);

// GET /api/dashboard/booking-manager
router.get('/booking-manager', protect, authorize('BOOKING_MANAGER'), bookingManagerDashboard);

// GET /api/dashboard/gh-manager
router.get('/gh-manager', protect, authorize('GH_MANAGER'), ghManagerDashboard);

module.exports = router;
