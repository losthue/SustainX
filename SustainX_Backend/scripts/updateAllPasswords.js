const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { sequelize, testConnection } = require('../config/db');
const User = require('../models/User');
const bcrypt = require('bcryptjs');

(async () => {
  try {
    await testConnection();
    await sequelize.sync({ alter: true });

    // Hash the new password
    const newPassword = 'test1234';
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update all users' password hashes
    const [affectedRows] = await User.update(
      { password_hash: hashedPassword },
      { where: {} } // Update all users
    );

    console.log(`✓ Updated password hashes for ${affectedRows} users to "test1234"`);

    // Verify by checking a few users
    const users = await User.findAll({
      attributes: ['user_id', 'email'],
      limit: 5
    });

    console.log('\nSample users updated:');
    users.forEach(user => {
      console.log(`- ${user.user_id}: ${user.email}`);
    });

  } catch (error) {
    console.error('Error updating passwords:', error);
  } finally {
    await sequelize.close();
  }
})();