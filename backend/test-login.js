require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

const MONGODB_URI = process.env.MONGODB_URI;

mongoose
  .connect(MONGODB_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(async () => {
    const user = await User.findOne({ email: 'admin@gh.com' });
    if (!user) {
      console.log('❌ User not found');
      process.exit(1);
    }

    // Test password
    const isMatch = await user.comparePassword('admin123');
    console.log('Testing password "admin123":');
    console.log(isMatch ? '✅ Password matches!' : '❌ Password does NOT match');

    process.exit(0);
  })
  .catch(err => {
    console.error('Error:', err.message);
    process.exit(1);
  });
