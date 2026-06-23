const express = require('express');
const router = express.Router();
const { getBookings, markPayment, checkout } = require('../controllers/bookingsController');
const { protect, authorize } = require('../middleware/auth');

// GET /api/bookings
router.get('/', protect, authorize('ADMIN', 'BOOKING_MANAGER', 'GH_MANAGER'), getBookings);

// PATCH /api/bookings/:id/payment
router.patch('/:id/payment', protect, authorize('ADMIN', 'BOOKING_MANAGER'), markPayment);

// PATCH /api/bookings/:id/checkout
router.patch('/:id/checkout', protect, authorize('ADMIN', 'BOOKING_MANAGER'), checkout);

module.exports = router;
