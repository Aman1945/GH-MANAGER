const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { createError } = require('../utils/helpers');

const signToken = (user) => {
  return jwt.sign(
    { id: user._id, role: user.role, guestHouseId: user.guestHouseId },
    process.env.JWT_SECRET,
    { expiresIn: '48h' }
  );
};

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return next(createError('Email and password are required', 400));
    }

    const user = await User.findOne({ email: email.toLowerCase() }).populate('guestHouseId', 'name location');
    if (!user) {
      return next(createError('Invalid email or password', 401));
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return next(createError('Invalid email or password', 401));
    }

    const token = signToken(user);

    // Create session record for tracking
    const Session = require('../models/Session');
    await Session.create({
      userId: user._id,
      email: user.email,
      role: user.role,
      deviceId: req.headers['user-agent'] || 'unknown',
      deviceInfo: {
        platform: req.headers['device-platform'] || 'web',
        model: req.headers['device-model'] || 'unknown',
        appVersion: req.headers['app-version'] || '1.0'
      },
      token,
      ipAddress: req.ip,
      expiresAt: new Date(Date.now() + 48 * 60 * 60 * 1000) // 48 hours
    });

    res.status(200).json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        guestHouseId: user.guestHouseId
      }
    });
  } catch (err) {
    next(err);
  }
};

const getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id).populate('guestHouseId', 'name location');
    res.status(200).json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
};

const logout = async (req, res, next) => {
  try {
    const Session = require('../models/Session');
    const userId = req.user.id;

    // Force logout: delete all sessions for this user
    await Session.deleteMany({ userId });

    res.status(200).json({
      success: true,
      message: 'Logged out successfully. Please login again.'
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { login, getMe, logout };
