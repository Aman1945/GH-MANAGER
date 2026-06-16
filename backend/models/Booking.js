const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema(
  {
    leadId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Lead',
      required: true
    },
    roomId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Room',
      required: true
    },
    guestHouseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'GuestHouse',
      required: true
    },
    guestName: { type: String, trim: true },
    checkIn: { type: Date },
    checkOut: { type: Date },
    approvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null
    },
    approvedAt: { type: Date, default: null },
    paymentStatus: {
      type: String,
      enum: ['PENDING', 'PAID'],
      default: 'PENDING'
    },
    bookingStatus: {
      type: String,
      enum: ['CONFIRMED', 'COMPLETED', 'CANCELLED'],
      default: 'CONFIRMED'
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Booking', bookingSchema);
