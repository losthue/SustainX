const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { sequelize, testConnection } = require('../config/db');

(async () => {
  try {
    await testConnection();

    const sql = fs.readFileSync(path.resolve(__dirname, '../update_rates.sql'), 'utf8');

    const startToken = 'CREATE PROCEDURE generate_coins_for_cycle';
    const startIndex = sql.indexOf(startToken);
    if (startIndex === -1) throw new Error('No generate_coins_for_cycle procedure found in update_rates.sql');

    const endToken = 'END$$';
    const endIndex = sql.indexOf(endToken, startIndex);
    if (endIndex === -1) throw new Error('No END$$ token found in update_rates.sql for procedure');

    let procSQL = sql.substring(startIndex, endIndex);
    procSQL = procSQL.trim();
    procSQL += '\nEND;';

    console.log('Procedure SQL snippet:', procSQL.substring(0, 260));

    await sequelize.query('DROP PROCEDURE IF EXISTS generate_coins_for_cycle');
    await sequelize.query(procSQL);

    console.log('✓ generate_coins_for_cycle synced successfully');
  } catch (err) {
    console.error('Error syncing procedure:', err.message);
  } finally {
    await sequelize.close();
  }
})();