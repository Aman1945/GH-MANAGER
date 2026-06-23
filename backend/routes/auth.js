const express = require('express');
const router = express.Router();
const { login, getMe, logout } = require('../controllers/authController');
const { protect } = require('../middleware/auth');

// POST /api/auth/login - public
router.post('/login', login);

// GET /api/auth/me - protected
router.get('/me', protect, getMe);

// POST /api/auth/logout - protected (forced logout from all devices)
router.post('/logout', protect, logout);

module.exports = router;
