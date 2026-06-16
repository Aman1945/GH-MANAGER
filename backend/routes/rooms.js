const express = require('express');
const router = express.Router();
const { getRooms, getAvailability } = require('../controllers/roomsController');
const { protect, authorize } = require('../middleware/auth');

// GET /api/rooms/availability - must be before /:id routes
router.get('/availability', protect, authorize('BOOKING_MANAGER', 'ADMIN'), getAvailability);

// GET /api/rooms
router.get('/', protect, getRooms);

module.exports = router;
