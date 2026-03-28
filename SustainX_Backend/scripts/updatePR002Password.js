const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { sequelize, testConnection } = require('../config/db');
const User = require('../models/User');
const bcrypt = require('bcryptjs');

(async () => {
  try {
    await testConnection();
    await sequelize.sync({ alter: true });

    // Find PR002 user
    const user = await User.findOne({ where: { user_id: 'PR002' } });

    if (!user) {
      console.log('User PR002 not found. Creating user...');

      // Create PR002 if doesn't exist
      const newUser = await User.create({
        user_id: 'PR002',
        username: 'prosumer002',
        email: 'pr002@sustainx.local',
        password_hash: 'Prosumer@2026', // Will be hashed by hook
        full_name: 'Prosumer 02',
        user_type: 'prosumer',
        is_active: true,
      });

      console.log('\n✓ User PR002 created successfully!\n');
      console.log('🆔 User ID:', newUser.user_id);
      console.log('📧 Email:', newUser.email);
      console.log('🔑 Password: Prosumer@2026');
      console.log('\nYou can now login with user_id + password.\n');
    } else {
      // Update existing user's password
      user.password_hash = 'Prosumer@2026'; // Will be hashed by hook
      await user.save();

      console.log('\n✓ User PR002 password updated successfully!\n');
      console.log('🆔 User ID:', user.user_id);
      console.log('📧 Email:', user.email);
      console.log('🔑 New Password: Prosumer@2026');
      console.log('\nYou can now login with user_id + password.\n');
    }

    await sequelize.close();
    process.exit(0);
  } catch (err) {
    console.error('Failed to update user PR002:', err.message);
    process.exit(1);
  }
})();
