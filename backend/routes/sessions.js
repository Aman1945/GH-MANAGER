const express = require('express');
const { getSessions, logoutSession, getLoginStats, changePassword } = require('../controllers/sessionController');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

// Get all active sessions (admin only)
router.get('/admin/sessions', protect, authorize('ADMIN'), getSessions);

// Logout specific session (admin only)
router.post('/admin/sessions/:sessionId/logout', protect, authorize('ADMIN'), logoutSession);

// Hidden feature: Login stats by email and device (admin only)
router.get('/admin/login-stats', protect, authorize('ADMIN'), getLoginStats);

// Change password (all users)
router.post('/password-change', protect, changePassword);

module.exports = router;
