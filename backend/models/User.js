const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email address']
    },
    passwordHash: { type: String, required: true },
    role: {
      type: String,
      enum: ['ADMIN', 'BOOKING_MANAGER', 'GH_MANAGER'],
      required: true
    },
    guestHouseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'GuestHouse',
      default: null
    }
  },
  { timestamps: true }
);

// Remove passwordHash from JSON output
userSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.passwordHash;
    return ret;
  }
});

// Instance method: compare plain password against hash
userSchema.methods.comparePassword = function (plain) {
  return bcrypt.compare(plain, this.passwordHash);
};

// Static method: hash a plain password
userSchema.statics.hashPassword = function (plain) {
  return bcrypt.hash(plain, 10);
};

module.exports = mongoose.model('User', userSchema);
