require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');

const MONGODB_URI = process.env.MONGODB_URI;

mongoose
  .connect(MONGODB_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(async () => {
    // Delete if exists
    await User.deleteOne({ email: 'admin@gh.com' });
    console.log('Deleted old admin@gh.com if existed');

    // Create fresh
    const password = 'admin123';
    const hashedPassword = await bcrypt.hash(password, 10);

    const newAdmin = new User({
      name: 'BigSams Admin',
      email: 'admin@gh.com',
      passwordHash: hashedPassword,
      role: 'ADMIN',
      guestHouseId: null
    });

    await newAdmin.save();
    console.log('✅ Fresh admin@gh.com created!\n');
    console.log('📧 Email: admin@gh.com');
    console.log('🔐 Password: admin123');

    process.exit(0);
  })
  .catch(err => {
    console.error('Error:', err.message);
    process.exit(1);
  });
