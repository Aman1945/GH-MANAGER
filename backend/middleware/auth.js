const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { createError } = require('../utils/helpers');

const protect = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(createError('No token provided', 401));
    }

    const token = authHeader.split(' ')[1];
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      return next(createError('Invalid or expired token', 401));
    }

    const user = await User.findById(decoded.id).populate('guestHouseId', 'name location');
    if (!user) {
      return next(createError('User not found', 401));
    }

    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return next(createError('Access denied: insufficient permissions', 403));
    }
    next();
  };
};

module.exports = { protect, authorize };
