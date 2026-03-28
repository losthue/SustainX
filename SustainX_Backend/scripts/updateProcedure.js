const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { sequelize, testConnection } = require('../config/db');
const fs = require('fs');

(async () => {
  try {
    await testConnection();

    // Read the update_rates.sql file
    const sqlContent = fs.readFileSync('./update_rates.sql', 'utf8');

    // Execute the entire file as one query (it contains DELIMITER changes)
    await sequelize.query(sqlContent);

    console.log('✓ Successfully updated stored procedure');

  } catch (error) {
    console.error('Error updating stored procedure:', error);
  } finally {
    await sequelize.close();
  }
})();