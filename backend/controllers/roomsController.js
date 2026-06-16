const Room = require('../models/Room');
const Booking = require('../models/Booking');
const { createError, checkOverlap } = require('../utils/helpers');

const getRooms = async (req, res, next) => {
  try {
    let query = {};

    if (req.user.role === 'GH_MANAGER') {
      // Force filter to this manager's guest house
      const ghId = req.user.guestHouseId
        ? req.user.guestHouseId._id || req.user.guestHouseId
        : null;
      query.guestHouseId = ghId;
    } else if (req.query.guestHouseId) {
      query.guestHouseId = req.query.guestHouseId;
    }

    const rooms = await Room.find(query)
      .populate('guestHouseId', 'name location')
      .sort({ guestHouseId: 1, roomNumber: 1 });

    res.status(200).json({ success: true, data: rooms });
  } catch (err) {
    next(err);
  }
};

const getAvailability = async (req, res, next) => {
  try {
    const { guestHouseId, checkIn, checkOut } = req.query;

    if (!guestHouseId || !checkIn || !checkOut) {
      return next(createError('guestHouseId, checkIn, and checkOut are required', 400));
    }

    const checkInDate = new Date(checkIn);
    const checkOutDate = new Date(checkOut);

    if (isNaN(checkInDate.getTime()) || isNaN(checkOutDate.getTime())) {
      return next(createError('Invalid date format', 400));
    }

    if (checkOutDate <= checkInDate) {
      return next(createError('checkOut must be after checkIn', 400));
    }

    // Get all AVAILABLE rooms in the guest house
    const rooms = await Room.find({ guestHouseId, status: 'AVAILABLE' })
      .populate('guestHouseId', 'name location');

    // For each room, check if there are overlapping CONFIRMED bookings
    const availableRooms = [];
    for (const room of rooms) {
      const conflicting = await Booking.findOne({
        roomId: room._id,
        bookingStatus: 'CONFIRMED',
        checkIn: { $lt: checkOutDate },
        checkOut: { $gt: checkInDate }
      });

      if (!conflicting) {
        availableRooms.push(room);
      }
    }

    res.status(200).json({ success: true, data: availableRooms });
  } catch (err) {
    next(err);
  }
};

module.exports = { getRooms, getAvailability };
