const express = require('express');
const router = express.Router();
const GuestHouse = require('../models/GuestHouse');
const { protect } = require('../middleware/auth');

// GET /api/guest-houses — all roles can list guest houses
router.get('/', protect, async (req, res, next) => {
  try {
    const guestHouses = await GuestHouse.find({}).sort({ name: 1 });
    res.json({ success: true, data: guestHouses });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
