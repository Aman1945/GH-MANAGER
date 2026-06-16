const MaintenanceRequest = require('../models/MaintenanceRequest');
const Booking = require('../models/Booking');
const Room = require('../models/Room');
const { createError } = require('../utils/helpers');

const getMaintenanceRequests = async (req, res, next) => {
  try {
    let query = {};

    // GH managers only see their own guest house's requests
    if (req.user.role === 'GH_MANAGER') {
      const ghId = req.user.guestHouseId
        ? req.user.guestHouseId._id || req.user.guestHouseId
        : null;
      query.guestHouseId = ghId;
    }

    const requests = await MaintenanceRequest.find(query)
      .populate('roomId', 'roomNumber status')
      .populate('guestHouseId', 'name')
      .populate('reportedBy', 'name')
      .populate('bookingId', 'guestName')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, data: requests });
  } catch (err) {
    next(err);
  }
};

const createMaintenanceRequest = async (req, res, next) => {
  try {
    const { bookingId, roomId, description } = req.body;

    if (!description || !description.trim()) {
      return next(createError('description is required', 400));
    }

    let resolvedRoomId = roomId;
    let resolvedGuestHouseId = null;
    let resolvedBookingId = bookingId || null;

    // If a booking is referenced, derive room + guest house from it
    if (bookingId) {
      const booking = await Booking.findById(bookingId);
      if (!booking) {
        return next(createError('Booking not found', 404));
      }
      resolvedRoomId = booking.roomId;
      resolvedGuestHouseId = booking.guestHouseId;
    } else if (roomId) {
      const room = await Room.findById(roomId);
      if (!room) {
        return next(createError('Room not found', 404));
      }
      resolvedGuestHouseId = room.guestHouseId;
    } else {
      return next(createError('bookingId or roomId is required', 400));
    }

    // Enforce GH manager scoping — can only report for their own guest house
    const ghId = req.user.guestHouseId
      ? req.user.guestHouseId._id || req.user.guestHouseId
      : null;
    if (ghId && String(resolvedGuestHouseId) !== String(ghId)) {
      return next(createError('You can only report issues for your own guest house', 403));
    }

    const request = await MaintenanceRequest.create({
      roomId: resolvedRoomId,
      bookingId: resolvedBookingId,
      guestHouseId: resolvedGuestHouseId,
      description: description.trim(),
      reportedBy: req.user._id
    });

    // Flag the room as under maintenance so it is not re-assigned
    await Room.findByIdAndUpdate(resolvedRoomId, { status: 'MAINTENANCE' });

    const populated = await MaintenanceRequest.findById(request._id)
      .populate('roomId', 'roomNumber status')
      .populate('guestHouseId', 'name')
      .populate('reportedBy', 'name')
      .populate('bookingId', 'guestName');

    res.status(201).json({ success: true, data: populated });
  } catch (err) {
    next(err);
  }
};

const resolveMaintenanceRequest = async (req, res, next) => {
  try {
    const { id } = req.params;

    const request = await MaintenanceRequest.findById(id);
    if (!request) {
      return next(createError('Maintenance request not found', 404));
    }

    request.status = 'RESOLVED';
    await request.save();

    // Return the room to service
    await Room.findByIdAndUpdate(request.roomId, { status: 'AVAILABLE' });

    const populated = await MaintenanceRequest.findById(request._id)
      .populate('roomId', 'roomNumber status')
      .populate('guestHouseId', 'name')
      .populate('reportedBy', 'name')
      .populate('bookingId', 'guestName');

    res.status(200).json({ success: true, data: populated });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getMaintenanceRequests,
  createMaintenanceRequest,
  resolveMaintenanceRequest
};
