const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { sequelize, testConnection } = require('../config/db');

(async () => {
  try {
    await testConnection();

    // Create the simpler stored procedure from schema.sql
    const procedureSQL = `
DELIMITER $$

DROP PROCEDURE IF EXISTS generate_coins_for_cycle$$

CREATE PROCEDURE generate_coins_for_cycle(
    IN p_billing_cycle INT,
    IN p_yellow_rate DECIMAL(5,3),
    IN p_red_rate DECIMAL(5,3)
)
BEGIN
    -- Insert / update generation log for this cycle
    INSERT INTO coin_generation_log (
        user_id, billing_cycle,
        import_kwh, export_kwh, net_kwh,
        yellow_coins_minted, green_coins_minted, red_coins_minted
    )
    SELECT
        user_id,
        billing_cycle,
        COALESCE(import_kwh, 0),
        COALESCE(export_kwh, 0),
        COALESCE(net_kwh, COALESCE(export_kwh, 0) - COALESCE(import_kwh, 0)),
        -- 🟡 Yellow: surplus × rate (prosumers with net export)
        CASE WHEN COALESCE(net_kwh, COALESCE(export_kwh, 0) - COALESCE(import_kwh, 0)) > 0 THEN COALESCE(net_kwh, COALESCE(export_kwh, 0) - COALESCE(import_kwh, 0)) * p_yellow_rate ELSE 0 END,
        -- 🟢 Green: always 0 — NOT minted from energy readings
        0,
        -- 🔴 Red: deficit × rate
        CASE WHEN COALESCE(net_kwh, COALESCE(export_kwh, 0) - COALESCE(import_kwh, 0)) < 0 THEN ABS(COALESCE(net_kwh, COALESCE(export_kwh, 0) - COALESCE(import_kwh, 0))) * p_red_rate ELSE 0 END
    FROM energy_readings
    WHERE billing_cycle = p_billing_cycle
    ON DUPLICATE KEY UPDATE
        yellow_coins_minted = VALUES(yellow_coins_minted),
        green_coins_minted  = 0,
        red_coins_minted    = VALUES(red_coins_minted);

    -- Update wallet balances (yellow and red only; green unchanged)
    UPDATE wallets w
    JOIN coin_generation_log cgl
        ON w.user_id = cgl.user_id
       AND cgl.billing_cycle = p_billing_cycle
    SET
        w.yellow_coins = w.yellow_coins + cgl.yellow_coins_minted,
        w.red_coins    = w.red_coins    + cgl.red_coins_minted,
        w.updated_at   = CURRENT_TIMESTAMP;

    -- Log yellow coin minting
    INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, billing_cycle, note, status)
    SELECT NULL, cgl.user_id, 'yellow', cgl.yellow_coins_minted, 'mint',
           p_billing_cycle, CONCAT('Yellow minted cycle ', p_billing_cycle), 'completed'
    FROM coin_generation_log cgl
    WHERE cgl.billing_cycle = p_billing_cycle AND cgl.yellow_coins_minted > 0;

    -- Log red coin minting
    INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, billing_cycle, note, status)
    SELECT NULL, cgl.user_id, 'red', cgl.red_coins_minted, 'mint',
           p_billing_cycle, CONCAT('Red minted cycle ', p_billing_cycle), 'completed'
    FROM coin_generation_log cgl
    WHERE cgl.billing_cycle = p_billing_cycle AND cgl.red_coins_minted > 0;
END$$

DELIMITER ;
    `;

    await sequelize.query(procedureSQL);

    console.log('✓ Successfully created stored procedure generate_coins_for_cycle (3-parameter version)');

  } catch (error) {
    console.error('Error creating stored procedure:', error);
  } finally {
    await sequelize.close();
  }
})();