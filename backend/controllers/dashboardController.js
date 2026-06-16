const Lead = require('../models/Lead');
const Room = require('../models/Room');
const Booking = require('../models/Booking');

const adminDashboard = async (req, res, next) => {
  try {
    const [
      pendingLeads,
      rejectedLeads,
      blockedRooms,
      confirmedBookings,
      occupiedRooms,
      totalLeads,
      totalBookings
    ] = await Promise.all([
      Lead.countDocuments({ status: 'PENDING' }),
      Lead.countDocuments({ status: 'REJECTED' }),
      Room.countDocuments({ status: 'BLOCKED' }),
      Booking.countDocuments({ bookingStatus: 'CONFIRMED' }),
      Room.countDocuments({ status: 'OCCUPIED' }),
      Lead.countDocuments(),
      Booking.countDocuments()
    ]);

    res.status(200).json({
      success: true,
      data: {
        pendingLeads,
        rejectedLeads,
        blockedRooms,
        confirmedBookings,
        occupiedRooms,
        totalLeads,
        totalBookings
      }
    });
  } catch (err) {
    next(err);
  }
};

const bookingManagerDashboard = async (req, res, next) => {
  try {
    const [pendingLeads, availableRooms, totalBookings] = await Promise.all([
      Lead.countDocuments({ status: 'PENDING' }),
      Room.countDocuments({ status: 'AVAILABLE' }),
      Booking.countDocuments()
    ]);

    res.status(200).json({
      success: true,
      data: {
        pendingLeads,
        availableRooms,
        totalBookings
      }
    });
  } catch (err) {
    next(err);
  }
};

const ghManagerDashboard = async (req, res, next) => {
  try {
    const ghId = req.user.guestHouseId
      ? req.user.guestHouseId._id || req.user.guestHouseId
      : null;

    const [occupiedRooms, availableRooms, blockedRooms, totalRooms] = await Promise.all([
      Room.countDocuments({ guestHouseId: ghId, status: 'OCCUPIED' }),
      Room.countDocuments({ guestHouseId: ghId, status: 'AVAILABLE' }),
      Room.countDocuments({ guestHouseId: ghId, status: 'BLOCKED' }),
      Room.countDocuments({ guestHouseId: ghId })
    ]);

    res.status(200).json({
      success: true,
      data: {
        occupiedRooms,
        availableRooms,
        blockedRooms,
        totalRooms
      }
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { adminDashboard, bookingManagerDashboard, ghManagerDashboard };
