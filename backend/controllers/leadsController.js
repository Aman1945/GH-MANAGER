const Lead = require('../models/Lead');
const GuestHouse = require('../models/GuestHouse');
const { createError } = require('../utils/helpers');
const { parseEmailToLead } = require('../utils/emailParser');

const getLeads = async (req, res, next) => {
  try {
    let query = {};

    if (req.user.role === 'BOOKING_MANAGER') {
      query.status = 'PENDING';
    }

    const leads = await Lead.find(query)
      .populate('preferredGuestHouseId', 'name')
      .populate('createdBy', 'name email')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, data: leads });
  } catch (err) {
    next(err);
  }
};

const createLead = async (req, res, next) => {
  try {
    const { guestName, phone, email, checkIn, checkOut, preferredGuestHouseId } = req.body;

    if (!guestName || !phone || !email) {
      return next(createError('guestName, phone, and email are required', 400));
    }

    if (!checkIn || !checkOut) {
      return next(createError('checkIn and checkOut dates are required', 400));
    }

    const checkInDate = new Date(checkIn);
    const checkOutDate = new Date(checkOut);

    if (isNaN(checkInDate.getTime()) || isNaN(checkOutDate.getTime())) {
      return next(createError('Invalid date format for checkIn or checkOut', 400));
    }

    if (checkOutDate <= checkInDate) {
      return next(createError('checkOut must be after checkIn', 400));
    }

    const lead = await Lead.create({
      guestName,
      phone,
      email,
      checkIn: checkInDate,
      checkOut: checkOutDate,
      preferredGuestHouseId: preferredGuestHouseId || null,
      source: 'MANUAL',
      createdBy: req.user._id
    });

    res.status(201).json({ success: true, data: lead });
  } catch (err) {
    next(err);
  }
};

// POST /api/leads/import-email — parse raw email text into a lead
const importFromEmail = async (req, res, next) => {
  try {
    const { emailText } = req.body;

    if (!emailText || !emailText.trim()) {
      return next(createError('emailText is required', 400));
    }

    const guestHouses = await GuestHouse.find().select('name');
    const { parsed, missing } = parseEmailToLead(emailText, guestHouses);

    // Dates are essential — without them we cannot create a valid lead
    if (missing.includes('checkIn') || missing.includes('checkOut')) {
      return next(
        createError(
          'Could not extract check-in/check-out dates from the email. Please create the lead manually.',
          422
        )
      );
    }

    if (parsed.checkOut <= parsed.checkIn) {
      return next(createError('Extracted check-out is not after check-in. Please review the email.', 422));
    }

    const lead = await Lead.create({
      guestName: parsed.guestName || 'Unknown Guest',
      phone: parsed.phone || 'N/A',
      email: parsed.email || 'unknown@email.com',
      checkIn: parsed.checkIn,
      checkOut: parsed.checkOut,
      preferredGuestHouseId: parsed.preferredGuestHouseId,
      source: 'EMAIL_AUTO',
      emailExcerpt: emailText.trim().slice(0, 300),
      createdBy: req.user._id
    });

    res.status(201).json({
      success: true,
      data: lead,
      meta: { extractedFields: parsed, missingFields: missing }
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { getLeads, createLead, importFromEmail };
