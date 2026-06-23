require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');

const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
  console.error('ERROR: MONGODB_URI is not set in .env');
  process.exit(1);
}

mongoose
  .connect(MONGODB_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(async () => {
    console.log('Connected to MongoDB. Creating admin@gh.com...');

    // Check if user already exists
    const existingUser = await User.findOne({ email: 'admin@gh.com' });
    if (existingUser) {
      console.log('❌ admin@gh.com already exists!');
      process.exit(0);
    }

    // Create strong password
    const password = 'BigSams@Admin123';
    const hashedPassword = await bcrypt.hash(password, 10);

    const newAdmin = new User({
      name: 'BigSams Admin',
      email: 'admin@gh.com',
      passwordHash: hashedPassword,
      role: 'ADMIN',
      guestHouseId: null
    });

    await newAdmin.save();

    console.log('\n✅ Admin account created successfully!\n');
    console.log('═══════════════════════════════════════');
    console.log('📧 Email:    admin@gh.com');
    console.log('🔐 Password: BigSams@Admin123');
    console.log('👤 Role:     ADMIN (Full Access)');
    console.log('═══════════════════════════════════════\n');
    console.log('Features available:');
    console.log('  ✓ Dashboard with 4 KPI cards');
    console.log('  ✓ Session Management (view/logout users)');
    console.log('  ✓ Hidden stats (devices per email)');
    console.log('  ✓ Login limits tracking');
    console.log('  ✓ Lead management');
    console.log('  ✓ Booking management');
    console.log('  ✓ Room management');
    console.log('  ✓ User approvals\n');

    process.exit(0);
  })
  .catch((err) => {
    console.error('Error:', err.message);
    process.exit(1);
  });
