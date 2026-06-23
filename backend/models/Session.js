const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    email: String,
    role: String,
    deviceId: String, // Device fingerprint
    deviceInfo: {
      platform: String, // Android, iOS, Web
      model: String, // Device model
      appVersion: String,
    },
    token: String,
    ipAddress: String,
    loginTime: { type: Date, default: Date.now },
    lastActivity: { type: Date, default: Date.now },
    expiresAt: Date,
  },
  { timestamps: true }
);

module.exports = mongoose.model('Session', sessionSchema);
