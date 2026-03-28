const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { sequelize, testConnection } = require('../config/db');
const User = require('../models/User');
const bcrypt = require('bcryptjs');

(async () => {
  try {
    await testConnection();
    await sequelize.sync({ alter: true });

    const testUser = await User.create({
      userId: 'PR001',
      username: 'prosumer001',
      email: 'prosumer001@sustainx.local',
      password: 'Test@12345',
      fullName: 'Prosumer 001',
    });

    console.log('\n✓ Test user created successfully!\n');
    console.log('🆔 User ID:', testUser.userId);
    console.log('📧 Email:', testUser.email);
    console.log('🔑 Password: Test@12345');
    console.log('\nYou can now use these credentials to login with user_id + password.\n');

    await sequelize.close();
    process.exit(0);
  } catch (err) {
    console.error('Failed to create test user:', err.message);
    process.exit(1);
  }
})();
