const Session = require('../models/Session');
const User = require('../models/User');

const getSessions = async (req, res, next) => {
  try {
    const sessions = await Session.find({ expiresAt: { $gt: new Date() } })
      .populate('userId', 'name email role')
      .sort({ loginTime: -1 });

    res.status(200).json({
      success: true,
      data: sessions.map(s => ({
        id: s._id,
        userId: s.userId._id,
        name: s.userId.name,
        email: s.email,
        role: s.role,
        device: s.deviceInfo?.platform || 'Web',
        deviceModel: s.deviceInfo?.model,
        loginTime: s.loginTime,
        lastActivity: s.lastActivity,
      }))
    });
  } catch (err) {
    next(err);
  }
};

const logoutSession = async (req, res, next) => {
  try {
    const { sessionId } = req.params;
    await Session.findByIdAndDelete(sessionId);

    res.status(200).json({
      success: true,
      message: 'User logged out successfully'
    });
  } catch (err) {
    next(err);
  }
};

const getLoginStats = async (req, res, next) => {
  try {
    // Hidden feature: Device login stats
    const emailStats = await Session.aggregate([
      { $match: { expiresAt: { $gt: new Date() } } },
      {
        $group: {
          _id: '$email',
          totalDevices: { $sum: 1 },
          devices: { $push: '$deviceInfo.platform' },
          lastLogin: { $max: '$loginTime' }
        }
      },
      { $sort: { lastLogin: -1 } }
    ]);

    const roleStats = await Session.aggregate([
      { $match: { expiresAt: { $gt: new Date() } } },
      {
        $group: {
          _id: '$role',
          count: { $sum: 1 }
        }
      }
    ]);

    res.status(200).json({
      success: true,
      data: {
        emailDeviceStats: emailStats,
        roleStats: roleStats,
        loginLimits: {
          ADMIN: { limit: 5, used: roleStats.find(r => r._id === 'ADMIN')?.count || 0 },
          BOOKING_MANAGER: { limit: 10, used: roleStats.find(r => r._id === 'BOOKING_MANAGER')?.count || 0 },
          GH_MANAGER: { limit: 20, used: roleStats.find(r => r._id === 'GH_MANAGER')?.count || 0 }
        }
      }
    });
  } catch (err) {
    next(err);
  }
};

const changePassword = async (req, res, next) => {
  try {
    const { oldPassword, newPassword } = req.body;
    const userId = req.user.id;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const bcrypt = require('bcryptjs');
    const isMatch = await bcrypt.compare(oldPassword, user.passwordHash);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Current password is incorrect' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.passwordHash = hashedPassword;
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { getSessions, logoutSession, getLoginStats, changePassword };
