const { Sequelize } = require('sequelize');
const config = require('./config');

const sequelize = new Sequelize(
  config.db.database,
  config.db.username,
  config.db.password,
  {
    host: config.db.host,
    port: config.db.port,
    dialect: 'mysql',
    logging: false,
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000,
    },
  }
);

const testConnection = async () => {
  try {
    await sequelize.authenticate();
    console.log('✓ MySQL connection established');
  } catch (error) {
    console.error('✗ MySQL connection error:', error.message);
    process.exit(1);
  }
};

const ensureSchema = async () => {
  try {
    const [columns] = await sequelize.query('SHOW COLUMNS FROM transactions');
    const fields = columns.map((column) => column.Field);

    if (!fields.includes('amount_rs')) {
      await sequelize.query(
        'ALTER TABLE transactions ADD COLUMN amount_rs DECIMAL(10,2) DEFAULT NULL AFTER amount'
      );
    }

    // Ensure coin_type and transaction_type enums include required values.
    await sequelize.query(
      "ALTER TABLE transactions MODIFY COLUMN coin_type ENUM('green','red','yellow') NOT NULL"
    );
    await sequelize.query(
      "ALTER TABLE transactions MODIFY COLUMN transaction_type ENUM('mint','transfer','offset','sale','purchase','burn') NOT NULL"
    );

    // Ensure users has stripe_customer_id for Stripe integration
    const [userColumns] = await sequelize.query("SHOW COLUMNS FROM users LIKE 'stripe_customer_id'");
    if (userColumns.length === 0) {
      await sequelize.query(
        "ALTER TABLE users ADD COLUMN stripe_customer_id VARCHAR(100) NULL AFTER password_hash"
      );
      console.log('✓ Added missing stripe_customer_id column to users');
    }

    const [tables] = await sequelize.query("SHOW TABLES LIKE 'admin_profit'");
    if (tables.length === 0) {
      await sequelize.query(`
        CREATE TABLE admin_profit (
          profit_id   INT AUTO_INCREMENT PRIMARY KEY,
          seller_id   VARCHAR(10) NOT NULL,
          buyer_id    VARCHAR(10) NOT NULL,
          yellow_sold DECIMAL(10,4) NOT NULL,
          gross_rs    DECIMAL(10,2) NOT NULL,
          profit_rs   DECIMAL(10,2) NOT NULL,
          buyer_green DECIMAL(10,4) NOT NULL,
          created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (seller_id) REFERENCES users(user_id),
          FOREIGN KEY (buyer_id) REFERENCES users(user_id)
        )
      `);
      console.log('✓ Created missing admin_profit table');
    }

    // Check if the stored procedure exists
    const [procedures] = await sequelize.query(
      "SHOW PROCEDURE STATUS WHERE Name = 'generate_coins_for_cycle' AND Db = DATABASE()"
    );

    if (procedures.length === 0) {
      console.log('⚠️ Stored procedure generate_coins_for_cycle not found, creating...');

      // Create a simple version of the procedure
      const createProcedureSQL = `
        CREATE PROCEDURE generate_coins_for_cycle(
            IN p_billing_cycle INT,
            IN p_yellow_rate DECIMAL(5,3),
            IN p_red_rate DECIMAL(5,3)
        )
        BEGIN
            INSERT INTO coin_generation_log (
                user_id, billing_cycle,
                import_kwh, export_kwh, net_kwh,
                yellow_coins_minted, green_coins_minted, red_coins_minted
            )
            SELECT
                user_id, billing_cycle,
                COALESCE(import_kwh, 0), COALESCE(export_kwh, 0),
                COALESCE(net_kwh, COALESCE(export_kwh, 0) - COALESCE(import_kwh, 0)),
                CASE WHEN COALESCE(net_kwh, COALESCE(export_kwh, 0) - COALESCE(import_kwh, 0)) > 0
                     THEN COALESCE(net_kwh, COALESCE(export_kwh, 0) - COALESCE(import_kwh, 0)) * p_yellow_rate ELSE 0 END,
                0,
                CASE WHEN COALESCE(net_kwh, COALESCE(export_kwh, 0) - COALESCE(import_kwh, 0)) < 0
                     THEN ABS(COALESCE(net_kwh, COALESCE(export_kwh, 0) - COALESCE(import_kwh, 0))) * p_red_rate ELSE 0 END
            FROM energy_readings
            WHERE billing_cycle = p_billing_cycle
            ON DUPLICATE KEY UPDATE
                yellow_coins_minted = VALUES(yellow_coins_minted),
                red_coins_minted = VALUES(red_coins_minted);

            UPDATE wallets w
            JOIN coin_generation_log cgl ON w.user_id = cgl.user_id AND cgl.billing_cycle = p_billing_cycle
            SET w.yellow_coins = w.yellow_coins + cgl.yellow_coins_minted,
                w.red_coins = w.red_coins + cgl.red_coins_minted,
                w.updated_at = CURRENT_TIMESTAMP;
        END
      `;

      await sequelize.query(createProcedureSQL);
      console.log('✓ Created stored procedure generate_coins_for_cycle');
    }

    console.log('✓ Schema check/repair completed: transactions/admin_profit tables and procedures are correct');
  } catch (error) {
    console.warn('⚠️ Schema repair warning:', error.message);
  }
};

module.exports = { sequelize, testConnection, ensureSchema };
