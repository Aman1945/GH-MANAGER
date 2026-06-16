const Booking = require('../models/Booking');
const Room = require('../models/Room');
const { createError } = require('../utils/helpers');

const getBookings = async (req, res, next) => {
  try {
    let query = {};

    if (req.user.role === 'GH_MANAGER') {
      const ghId = req.user.guestHouseId
        ? req.user.guestHouseId._id || req.user.guestHouseId
        : null;
      query.guestHouseId = ghId;
    }

    const bookings = await Booking.find(query)
      .populate('roomId', 'roomNumber status')
      .populate('guestHouseId', 'name')
      .populate('approvedBy', 'name')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, data: bookings });
  } catch (err) {
    next(err);
  }
};

const markPayment = async (req, res, next) => {
  try {
    const { id } = req.params;

    const booking = await Booking.findById(id);
    if (!booking) {
      return next(createError('Booking not found', 404));
    }
    if (booking.bookingStatus !== 'CONFIRMED') {
      return next(createError('Only CONFIRMED bookings can take a payment', 400));
    }
    if (booking.paymentStatus === 'PAID') {
      return next(createError('Payment has already been recorded for this booking', 400));
    }

    booking.paymentStatus = 'PAID';
    await booking.save();

    // Update room status → OCCUPIED
    await Room.findByIdAndUpdate(booking.roomId, { status: 'OCCUPIED' });

    const populated = await Booking.findById(booking._id)
      .populate('roomId', 'roomNumber status')
      .populate('guestHouseId', 'name')
      .populate('approvedBy', 'name');

    res.status(200).json({ success: true, data: populated });
  } catch (err) {
    next(err);
  }
};

const checkout = async (req, res, next) => {
  try {
    const { id } = req.params;

    const booking = await Booking.findById(id);
    if (!booking) {
      return next(createError('Booking not found', 404));
    }
    if (booking.bookingStatus !== 'CONFIRMED') {
      return next(createError('Only CONFIRMED bookings can be checked out', 400));
    }
    if (booking.paymentStatus !== 'PAID') {
      return next(createError('Payment must be received before checkout', 400));
    }

    booking.bookingStatus = 'COMPLETED';
    await booking.save();

    // Update room status → AVAILABLE
    await Room.findByIdAndUpdate(booking.roomId, { status: 'AVAILABLE' });

    const populated = await Booking.findById(booking._id)
      .populate('roomId', 'roomNumber status')
      .populate('guestHouseId', 'name')
      .populate('approvedBy', 'name');

    res.status(200).json({ success: true, data: populated });
  } catch (err) {
    next(err);
  }
};

module.exports = { getBookings, markPayment, checkout };
