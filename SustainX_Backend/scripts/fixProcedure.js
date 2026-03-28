const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { sequelize, testConnection } = require('../config/db');
const fs = require('fs');

(async () => {
  try {
    await testConnection();

    const schemaContent = fs.readFileSync('./sustainX_schema.sql', 'utf8');

    const procedureStart = schemaContent.indexOf('CREATE PROCEDURE generate_coins_for_cycle');
    const delimiterEnd = schemaContent.indexOf('DELIMITER ;', procedureStart);

    if (procedureStart !== -1 && delimiterEnd !== -1) {
      // Extract the full procedure block
      const procedureBlock = schemaContent.substring(procedureStart, delimiterEnd + 12);

      console.log('Found procedure block, executing...');

      // Execute the entire block
      await sequelize.query(procedureBlock);

      console.log('✓ Successfully created stored procedure generate_coins_for_cycle');
    } else {
      console.log('Procedure not found in schema.sql');
    }
  } catch (error) {
    console.error('Error creating stored procedure:', error);
  } finally {
    await sequelize.close();
  }
})();