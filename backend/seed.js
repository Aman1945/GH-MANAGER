require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const User = require('./models/User');
const GuestHouse = require('./models/GuestHouse');
const Room = require('./models/Room');
const Lead = require('./models/Lead');
const Booking = require('./models/Booking');
const MaintenanceRequest = require('./models/MaintenanceRequest');

const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
  console.error('ERROR: MONGODB_URI is not set in .env');
  process.exit(1);
}

// Helper: add days to a date
function addDays(date, days) {
  const d = new Date(date);
  d.setDate(d.getDate() + days);
  return d;
}

const today = new Date();

mongoose
  .connect(MONGODB_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(async () => {
    console.log('Connected to MongoDB. Starting seed...');

    // ─── 1. DROP ALL EXISTING DATA ────────────────────────────────────────────
    await Promise.all([
      User.deleteMany({}),
      GuestHouse.deleteMany({}),
      Room.deleteMany({}),
      Lead.deleteMany({}),
      Booking.deleteMany({}),
      MaintenanceRequest.deleteMany({})
    ]);
    console.log('Cleared all collections.');

    // ─── 2. GUEST HOUSES ─────────────────────────────────────────────────────
    const guestHouses = await GuestHouse.insertMany([
      { name: 'Beachside Villa', location: 'Goa' },
      { name: 'Mountain View Lodge', location: 'Shimla' },
      { name: 'City Center Inn', location: 'Mumbai' }
    ]);

    const beachsideVilla = guestHouses[0];
    const mountainLodge = guestHouses[1];
    const cityInn = guestHouses[2];
    console.log('Guest houses created:', guestHouses.map(g => g.name).join(', '));

    // ─── 3. ROOMS (5 per guest house) ────────────────────────────────────────
    const roomData = [];
    for (const gh of guestHouses) {
      for (let i = 1; i <= 5; i++) {
        roomData.push({
          guestHouseId: gh._id,
          roomNumber: String(i).padStart(3, '0'),
          status: 'AVAILABLE'
        });
      }
    }
    const rooms = await Room.insertMany(roomData);
    console.log(`${rooms.length} rooms created.`);

    // Rooms for Beachside Villa (first 5)
    const beachRooms = rooms.filter(r => r.guestHouseId.toString() === beachsideVilla._id.toString());

    // ─── 4. USERS ─────────────────────────────────────────────────────────────
    const adminHash = await bcrypt.hash('Admin@123', 10);
    const bookingHash = await bcrypt.hash('Book@123', 10);
    const ghHash = await bcrypt.hash('GH@123', 10);

    const users = await User.insertMany([
      {
        name: 'Admin User',
        email: 'admin@ghmanager.in',
        passwordHash: adminHash,
        role: 'ADMIN',
        guestHouseId: null
      },
      {
        name: 'Booking Manager',
        email: 'booking@ghmanager.in',
        passwordHash: bookingHash,
        role: 'BOOKING_MANAGER',
        guestHouseId: null
      },
      {
        name: 'Ramesh Naik',
        email: 'ramesh@ghmanager.in',
        passwordHash: ghHash,
        role: 'GH_MANAGER',
        guestHouseId: beachsideVilla._id
      },
      {
        name: 'Sunita Sharma',
        email: 'sunita@ghmanager.in',
        passwordHash: ghHash,
        role: 'GH_MANAGER',
        guestHouseId: mountainLodge._id
      },
      {
        name: 'Vikram Desai',
        email: 'vikram@ghmanager.in',
        passwordHash: ghHash,
        role: 'GH_MANAGER',
        guestHouseId: cityInn._id
      }
    ]);
    console.log(`${users.length} users created.`);

    const adminUser = users[0];

    // ─── 5. LEADS ─────────────────────────────────────────────────────────────
    const leadData = [
      // First 5 → will be APPROVED (bookings created)
      {
        guestName: 'Rahul Sharma',
        phone: '9876543210',
        email: 'rahul.sharma@gmail.com',
        checkIn: addDays(today, 30),
        checkOut: addDays(today, 35),
        preferredGuestHouseId: beachsideVilla._id,
        status: 'APPROVED',
        createdBy: adminUser._id
      },
      {
        guestName: 'Priya Patel',
        phone: '8765432109',
        email: 'priya.patel@gmail.com',
        checkIn: addDays(today, 35),
        checkOut: addDays(today, 40),
        preferredGuestHouseId: beachsideVilla._id,
        status: 'APPROVED',
        createdBy: adminUser._id
      },
      {
        guestName: 'Amit Verma',
        phone: '7654321098',
        email: 'amit.verma@gmail.com',
        checkIn: addDays(today, 40),
        checkOut: addDays(today, 45),
        preferredGuestHouseId: beachsideVilla._id,
        status: 'APPROVED',
        createdBy: adminUser._id
      },
      {
        guestName: 'Sneha Iyer',
        phone: '9123456789',
        email: 'sneha.iyer@gmail.com',
        checkIn: addDays(today, 45),
        checkOut: addDays(today, 50),
        preferredGuestHouseId: beachsideVilla._id,
        status: 'APPROVED',
        createdBy: adminUser._id
      },
      {
        guestName: 'Karan Malhotra',
        phone: '8234567890',
        email: 'karan.malhotra@gmail.com',
        checkIn: addDays(today, 50),
        checkOut: addDays(today, 57),
        preferredGuestHouseId: beachsideVilla._id,
        status: 'APPROVED',
        createdBy: adminUser._id
      },
      // Last 5 → PENDING
      {
        guestName: 'Deepika Singh',
        phone: '9345678901',
        email: 'deepika.singh@gmail.com',
        checkIn: addDays(today, 55),
        checkOut: addDays(today, 60),
        preferredGuestHouseId: mountainLodge._id,
        status: 'PENDING',
        createdBy: adminUser._id
      },
      {
        guestName: 'Ravi Kumar',
        phone: '8456789012',
        email: 'ravi.kumar@gmail.com',
        checkIn: addDays(today, 60),
        checkOut: addDays(today, 65),
        preferredGuestHouseId: cityInn._id,
        status: 'PENDING',
        createdBy: adminUser._id
      },
      {
        guestName: 'Ananya Reddy',
        phone: '7567890123',
        email: 'ananya.reddy@gmail.com',
        checkIn: addDays(today, 65),
        checkOut: addDays(today, 72),
        preferredGuestHouseId: beachsideVilla._id,
        status: 'PENDING',
        createdBy: adminUser._id
      },
      {
        guestName: 'Vijay Menon',
        phone: '9678901234',
        email: 'vijay.menon@gmail.com',
        checkIn: addDays(today, 70),
        checkOut: addDays(today, 75),
        preferredGuestHouseId: mountainLodge._id,
        status: 'PENDING',
        createdBy: adminUser._id
      },
      {
        guestName: 'Pooja Nair',
        phone: '8789012345',
        email: 'pooja.nair@gmail.com',
        checkIn: addDays(today, 80),
        checkOut: addDays(today, 87),
        preferredGuestHouseId: cityInn._id,
        status: 'PENDING',
        source: 'EMAIL_AUTO',
        emailExcerpt:
          'Dear Team, I would like to book a room at City Center Inn for 7 nights. ' +
          'Guest Name: Pooja Nair Phone: 8789012345 Email: pooja.nair@gmail.com. Please confirm availability.',
        createdBy: adminUser._id
      }
    ];

    // Bypass pre-save hook for approved leads (dates are valid anyway)
    const leads = await Lead.insertMany(leadData);
    console.log(`${leads.length} leads created.`);

    const approvedLeads = leads.slice(0, 5);

    // ─── 6. BOOKINGS from first 5 approved leads ──────────────────────────────
    const bookingDocs = approvedLeads.map((lead, idx) => ({
      leadId: lead._id,
      roomId: beachRooms[idx]._id,
      guestHouseId: beachsideVilla._id,
      guestName: lead.guestName,
      checkIn: lead.checkIn,
      checkOut: lead.checkOut,
      approvedBy: adminUser._id,
      approvedAt: new Date(),
      bookingStatus: 'CONFIRMED',
      paymentStatus: idx < 2 ? 'PAID' : 'PENDING'
    }));

    const bookings = await Booking.insertMany(bookingDocs);
    console.log(`${bookings.length} bookings created.`);

    // Update room statuses:
    // Rooms 0 & 1 → OCCUPIED (payment paid)
    // Rooms 2, 3, 4 → BLOCKED (confirmed, not paid)
    const roomUpdatePromises = beachRooms.map((room, idx) => {
      const newStatus = idx < 2 ? 'OCCUPIED' : 'BLOCKED';
      return Room.findByIdAndUpdate(room._id, { status: newStatus });
    });
    await Promise.all(roomUpdatePromises);
    console.log('Room statuses updated (2 OCCUPIED, 3 BLOCKED at Beachside Villa).');

    // ─── 7. MAINTENANCE REQUEST (GH manager reported an issue) ─────────────────
    const ghManagerBeach = users[2]; // Ramesh Naik → Beachside Villa
    const maintBooking = bookings[1]; // Priya Patel — currently OCCUPIED
    await MaintenanceRequest.create({
      roomId: maintBooking.roomId,
      bookingId: maintBooking._id,
      guestHouseId: beachsideVilla._id,
      reportedBy: ghManagerBeach._id,
      description: 'Air conditioning not cooling properly. Guest requested a room change.',
      status: 'OPEN'
    });
    // Flag that room as under maintenance
    await Room.findByIdAndUpdate(maintBooking.roomId, { status: 'MAINTENANCE' });
    console.log('1 maintenance request created (Room under MAINTENANCE at Beachside Villa).');

    console.log('\n✅ Seed completed successfully!\n');
    console.log('─────────────────────────────────────────');
    console.log('Login credentials:');
    console.log('  ADMIN:           admin@ghmanager.in    / Admin@123');
    console.log('  BOOKING MANAGER: booking@ghmanager.in / Book@123');
    console.log('  GH MANAGER (Goa): ramesh@ghmanager.in  / GH@123');
    console.log('  GH MANAGER (Shimla): sunita@ghmanager.in / GH@123');
    console.log('  GH MANAGER (Mumbai): vikram@ghmanager.in / GH@123');
    console.log('─────────────────────────────────────────\n');

    process.exit(0);
  })
  .catch((err) => {
    console.error('Seed failed:', err.message);
    process.exit(1);
  });
