-- Update stored procedure to accept dynamic rates

DROP PROCEDURE IF EXISTS generate_coins_for_cycle;

DELIMITER $$

CREATE PROCEDURE generate_coins_for_cycle(
    IN p_billing_cycle INT,
    IN p_yellow_rate DECIMAL(5,2),
    IN p_green_rate DECIMAL(5,2),
    IN p_red_rate DECIMAL(5,2)
)
BEGIN
    -- Use provided rates or defaults
    SET @yr = COALESCE(p_yellow_rate, 1.0);
    SET @gr = COALESCE(p_green_rate, 0.5);
    SET @rr = COALESCE(p_red_rate, 1.5);

    -- Step 1: Insert/update generation log
    INSERT INTO coin_generation_log (
        user_id, billing_cycle,
        import_kwh, export_kwh, net_kwh,
        yellow_coins_minted, green_coins_minted, red_coins_minted
    )
    SELECT
        user_id,
        billing_cycle,
        import_kwh,
        export_kwh,
        net_kwh,
        CASE WHEN net_kwh > 0 THEN ROUND(net_kwh * @yr, 4) ELSE 0 END,
        CASE WHEN net_kwh > 0 THEN ROUND(net_kwh * @gr, 4) ELSE 0 END,
        CASE WHEN net_kwh < 0 THEN ROUND(ABS(net_kwh) * @rr, 4) ELSE 0 END
    FROM energy_readings
    WHERE billing_cycle = p_billing_cycle
    ON DUPLICATE KEY UPDATE
        yellow_coins_minted = VALUES(yellow_coins_minted),
        green_coins_minted  = VALUES(green_coins_minted),
        red_coins_minted    = VALUES(red_coins_minted);

    -- Step 2: Add minted coins to wallets
    UPDATE wallets w
    JOIN coin_generation_log cgl
        ON w.user_id = cgl.user_id
       AND cgl.billing_cycle = p_billing_cycle
    SET
        w.yellow_coins = w.yellow_coins + cgl.yellow_coins_minted,
        w.green_coins  = w.green_coins  + cgl.green_coins_minted,
        w.red_coins    = w.red_coins    + cgl.red_coins_minted,
        w.updated_at   = CURRENT_TIMESTAMP;

    -- Step 3: Auto-offset green vs red
    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_offsets (
        user_id VARCHAR(10),
        offset_amount DECIMAL(10,4)
    );
    TRUNCATE TABLE tmp_offsets;

    INSERT INTO tmp_offsets (user_id, offset_amount)
    SELECT w.user_id, LEAST(w.green_coins, w.red_coins)
    FROM wallets w
    WHERE w.green_coins > 0
      AND w.red_coins > 0
      AND w.user_id IN (
          SELECT user_id FROM coin_generation_log WHERE billing_cycle = p_billing_cycle
      );

    UPDATE wallets w
    JOIN tmp_offsets t ON w.user_id = t.user_id
    SET
        w.green_coins = w.green_coins - t.offset_amount,
        w.red_coins   = w.red_coins   - t.offset_amount,
        w.updated_at  = CURRENT_TIMESTAMP;

    INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, billing_cycle, note, status)
    SELECT
        t.user_id, NULL, 'green', t.offset_amount, 'offset', p_billing_cycle,
        CONCAT('Auto-offset cycle ', p_billing_cycle), 'completed'
    FROM tmp_offsets t
    WHERE t.offset_amount > 0;

    DROP TEMPORARY TABLE IF EXISTS tmp_offsets;

    -- Step 4: Log mint transactions
    INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, billing_cycle, note, status)
    SELECT
        NULL, cgl.user_id, 'green', cgl.green_coins_minted, 'mint', p_billing_cycle,
        CONCAT('Mint cycle ', p_billing_cycle, ' (Y:', @yr, ' G:', @gr, ' R:', @rr, ')'), 'completed'
    FROM coin_generation_log cgl
    WHERE cgl.billing_cycle = p_billing_cycle
      AND cgl.green_coins_minted > 0;
END$$

DELIMITER ;
