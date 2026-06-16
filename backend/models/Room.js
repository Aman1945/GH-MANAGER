const mongoose = require('mongoose');

const roomSchema = new mongoose.Schema(
  {
    guestHouseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'GuestHouse',
      required: true
    },
    roomNumber: { type: String, required: true, trim: true },
    status: {
      type: String,
      enum: ['AVAILABLE', 'BLOCKED', 'OCCUPIED', 'MAINTENANCE'],
      default: 'AVAILABLE'
    }
  },
  { timestamps: true }
);

// Compound unique index: one roomNumber per guest house
roomSchema.index({ guestHouseId: 1, roomNumber: 1 }, { unique: true });

module.exports = mongoose.model('Room', roomSchema);
