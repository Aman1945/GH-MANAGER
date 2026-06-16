const mongoose = require('mongoose');

const leadSchema = new mongoose.Schema(
  {
    guestName: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    email: { type: String, required: true, trim: true, lowercase: true },
    checkIn: { type: Date, required: true },
    checkOut: { type: Date, required: true },
    preferredGuestHouseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'GuestHouse',
      default: null
    },
    status: {
      type: String,
      enum: ['PENDING', 'APPROVED', 'REJECTED'],
      default: 'PENDING'
    },
    source: {
      type: String,
      enum: ['MANUAL', 'EMAIL_AUTO'],
      default: 'MANUAL'
    },
    emailExcerpt: { type: String, default: null },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null
    }
  },
  { timestamps: true }
);

// Validate: checkOut must be after checkIn
leadSchema.pre('save', function (next) {
  if (this.checkOut <= this.checkIn) {
    const err = new Error('Check-out date must be after check-in date');
    err.statusCode = 400;
    return next(err);
  }
  next();
});

module.exports = mongoose.model('Lead', leadSchema);
