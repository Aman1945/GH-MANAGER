const Lead = require('../models/Lead');
const Room = require('../models/Room');
const Booking = require('../models/Booking');
const GuestHouse = require('../models/GuestHouse');
const { createError, checkOverlap } = require('../utils/helpers');
const { sendApprovalEmail } = require('../services/emailService');

const getPendingApprovals = async (req, res, next) => {
  try {
    const leads = await Lead.find({ status: 'PENDING' })
      .populate('preferredGuestHouseId', 'name')
      .populate('createdBy', 'name email')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, data: leads });
  } catch (err) {
    next(err);
  }
};

const approveLead = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { roomId } = req.body;

    if (!roomId) {
      return next(createError('roomId is required', 400));
    }

    // Find lead and validate
    const lead = await Lead.findById(id);
    if (!lead) {
      return next(createError('Lead not found', 404));
    }
    if (lead.status !== 'PENDING') {
      return next(createError('Lead is not in PENDING status', 400));
    }

    // Find room and validate
    const room = await Room.findById(roomId);
    if (!room) {
      return next(createError('Room not found', 404));
    }
    if (room.status !== 'AVAILABLE') {
      return next(createError('Room is not available', 400));
    }

    // Check for overlapping confirmed bookings for this room
    const existingBookings = await Booking.find({
      roomId: room._id,
      bookingStatus: 'CONFIRMED'
    });

    for (const existing of existingBookings) {
      if (checkOverlap(existing.checkIn, existing.checkOut, lead.checkIn, lead.checkOut)) {
        return next(createError('Room has a conflicting booking for the requested dates', 409));
      }
    }

    // Create booking
    const booking = await Booking.create({
      leadId: lead._id,
      roomId: room._id,
      guestHouseId: room.guestHouseId,
      guestName: lead.guestName,
      checkIn: lead.checkIn,
      checkOut: lead.checkOut,
      approvedBy: req.user._id,
      approvedAt: new Date()
    });

    // Update room status → BLOCKED
    room.status = 'BLOCKED';
    await room.save();

    // Update lead status → APPROVED
    lead.status = 'APPROVED';
    await lead.save();

    // Send confirmation email to the guest (non-blocking, fails gracefully)
    const guestHouse = await GuestHouse.findById(room.guestHouseId).select('name');
    sendApprovalEmail({
      to: lead.email,
      guestName: lead.guestName,
      guestHouseName: guestHouse ? guestHouse.name : 'our guest house',
      roomNumber: room.roomNumber,
      checkIn: lead.checkIn,
      checkOut: lead.checkOut
    }).catch((e) => console.error('[approveLead] email error:', e.message));

    res.status(201).json({ success: true, data: booking });
  } catch (err) {
    next(err);
  }
};

const rejectLead = async (req, res, next) => {
  try {
    const { id } = req.params;

    const lead = await Lead.findById(id);
    if (!lead) {
      return next(createError('Lead not found', 404));
    }
    if (lead.status !== 'PENDING') {
      return next(createError('Lead is not in PENDING status', 400));
    }

    lead.status = 'REJECTED';
    await lead.save();

    res.status(200).json({ success: true, data: lead });
  } catch (err) {
    next(err);
  }
};

module.exports = { getPendingApprovals, approveLead, rejectLead };
