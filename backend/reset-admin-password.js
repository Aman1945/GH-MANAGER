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
    console.log('Connected to MongoDB. Resetting password...');

    const password = 'admin123';
    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await User.findOneAndUpdate(
      { email: 'admin@gh.com' },
      { passwordHash: hashedPassword },
      { new: true }
    );

    if (result) {
      console.log('\n✅ Password changed successfully!\n');
      console.log('═══════════════════════════════════════');
      console.log('📧 Email:    admin@gh.com');
      console.log('🔐 Password: admin123');
      console.log('═══════════════════════════════════════\n');
    } else {
      console.log('❌ admin@gh.com not found!');
    }

    process.exit(0);
  })
  .catch((err) => {
    console.error('Error:', err.message);
    process.exit(1);
  });
