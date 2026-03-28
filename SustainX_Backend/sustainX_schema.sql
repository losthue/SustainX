-- ============================================================
--  SustainX Innovation Challenge 2026
--  Database Schema — Energy Wallet System
--  Coin Logic:
--    🟡 Yellow (Rs 4)  = Minted for prosumer net surplus; auto-offsets red debt; NOT transferable directly
--    🟢 Green  (Rs 7)  = Tradeable currency; obtained via marketplace purchase or P2P yellow→green sale
--    🔴 Red    (Rs 10) = Grid consumption debt; offset by yellow coins at 1:1 ratio
--
--  P2P Sale: seller burns yellow → buyer receives green
--    seller_value_Rs = yellow_sold × 4
--    green_credited  = seller_value_Rs × 0.80 / 7   (platform keeps 20%)
-- ============================================================


-- ============================================================
-- 1. USERS
-- ============================================================
CREATE TABLE users (
    user_id            VARCHAR(10)  PRIMARY KEY,
    user_type          ENUM('prosumer', 'consumer') NOT NULL,
    name               VARCHAR(100),
    email              VARCHAR(150) UNIQUE NOT NULL,
    password_hash      VARCHAR(255) NOT NULL,
    stripe_customer_id VARCHAR(100) NULL,
    is_active          BOOLEAN      DEFAULT TRUE,
    created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


-- ============================================================
-- 2. METERS  (one meter per user based on dataset)
-- ============================================================
CREATE TABLE meters (
    meter_id     VARCHAR(10)  PRIMARY KEY,
    user_id      VARCHAR(10)  NOT NULL UNIQUE,
    installed_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);


-- ============================================================
-- 3. ENERGY READINGS  (raw dataset — one row per user per cycle)
-- ============================================================
CREATE TABLE energy_readings (
    reading_id     INT           AUTO_INCREMENT PRIMARY KEY,
    user_id        VARCHAR(10)   NOT NULL,
    meter_id       VARCHAR(10)   NOT NULL,
    import_kwh     DECIMAL(10,3) NOT NULL DEFAULT 0,
    export_kwh     DECIMAL(10,3) NOT NULL DEFAULT 0,
    billing_cycle  INT           NOT NULL,

    -- Computed at insert time for fast querying
    net_kwh        DECIMAL(10,3) GENERATED ALWAYS AS (export_kwh - import_kwh) STORED,

    recorded_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (user_id, billing_cycle),
    FOREIGN KEY (user_id)  REFERENCES users(user_id),
    FOREIGN KEY (meter_id) REFERENCES meters(meter_id)
);


-- ============================================================
-- 4. WALLETS  (one wallet per user, running balances)
-- ============================================================
CREATE TABLE wallets (
    wallet_id     INT           AUTO_INCREMENT PRIMARY KEY,
    user_id       VARCHAR(10)   NOT NULL UNIQUE,

    -- 🟡 Yellow: display only — cumulative net contribution
    yellow_coins  DECIMAL(10,4) NOT NULL DEFAULT 0 CHECK (yellow_coins >= 0),

    -- 🟢 Green: spendable / transferable solar-origin coins
    green_coins   DECIMAL(10,4) NOT NULL DEFAULT 0 CHECK (green_coins >= 0),

    -- 🔴 Red: grid consumption debt — target = 0
    red_coins     DECIMAL(10,4) NOT NULL DEFAULT 0 CHECK (red_coins >= 0),

    created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);


-- ============================================================
-- 5. COIN GENERATION LOG  (audit: what was minted each cycle)
-- ============================================================
CREATE TABLE coin_generation_log (
    log_id                  INT           AUTO_INCREMENT PRIMARY KEY,
    user_id                 VARCHAR(10)   NOT NULL,
    billing_cycle           INT           NOT NULL,

    import_kwh              DECIMAL(10,3) NOT NULL,
    export_kwh              DECIMAL(10,3) NOT NULL,
    net_kwh                 DECIMAL(10,3) NOT NULL,

    -- What was generated this cycle
    yellow_coins_minted     DECIMAL(10,4) NOT NULL DEFAULT 0,
    green_coins_minted      DECIMAL(10,4) NOT NULL DEFAULT 0,
    red_coins_minted        DECIMAL(10,4) NOT NULL DEFAULT 0,

    generated_at            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (user_id, billing_cycle),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);


-- ============================================================
-- 6. TRANSACTIONS  (all wallet operations — transfers, offsets)
-- ============================================================
CREATE TABLE transactions (
    transaction_id   INT           AUTO_INCREMENT PRIMARY KEY,
    sender_id        VARCHAR(10),                          -- NULL for system mint/burn
    receiver_id      VARCHAR(10),                          -- NULL for burns
    coin_type        ENUM('green', 'red', 'yellow') NOT NULL,
    amount           DECIMAL(10,4) NOT NULL CHECK (amount > 0),
    amount_rs        DECIMAL(10,2) DEFAULT NULL,  -- monetary Rs value of this transaction

    transaction_type ENUM(
        'mint',       -- system creates coins after energy reading
        'transfer',   -- user sends green coins to another user
        'offset',     -- yellow coins used to cancel red coins
        'sale',       -- prosumer sells yellow coins (yellow deducted)
        'purchase',   -- buyer receives green coins from a sale or marketplace
        'burn'        -- removing excess or expired value
    ) NOT NULL,

    billing_cycle    INT,
    note             VARCHAR(255),
    status           ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (sender_id)   REFERENCES users(user_id),
    FOREIGN KEY (receiver_id) REFERENCES users(user_id)
);


-- ============================================================
-- 7. SEED DATA — Users
-- ============================================================
INSERT INTO users (user_id, user_type, name, email, password_hash) VALUES
  ('PR001', 'prosumer', 'Prosumer 01', 'pr001@sustainx.com', 'hashed_pw'),
  ('PR002', 'prosumer', 'Prosumer 02', 'pr002@sustainx.com', 'hashed_pw'),
  ('PR003', 'prosumer', 'Prosumer 03', 'pr003@sustainx.com', 'hashed_pw'),
  ('PR004', 'prosumer', 'Prosumer 04', 'pr004@sustainx.com', 'hashed_pw'),
  ('PR005', 'prosumer', 'Prosumer 05', 'pr005@sustainx.com', 'hashed_pw'),
  ('PR006', 'prosumer', 'Prosumer 06', 'pr006@sustainx.com', 'hashed_pw'),
  ('PR007', 'prosumer', 'Prosumer 07', 'pr007@sustainx.com', 'hashed_pw'),
  ('PR008', 'prosumer', 'Prosumer 08', 'pr008@sustainx.com', 'hashed_pw'),
  ('PR009', 'prosumer', 'Prosumer 09', 'pr009@sustainx.com', 'hashed_pw'),
  ('PR010', 'prosumer', 'Prosumer 10', 'pr010@sustainx.com', 'hashed_pw'),
  ('C001',  'consumer', 'Consumer 01', 'c001@sustainx.com',  'hashed_pw'),
  ('C002',  'consumer', 'Consumer 02', 'c002@sustainx.com',  'hashed_pw'),
  ('C003',  'consumer', 'Consumer 03', 'c003@sustainx.com',  'hashed_pw'),
  ('C004',  'consumer', 'Consumer 04', 'c004@sustainx.com',  'hashed_pw'),
  ('C005',  'consumer', 'Consumer 05', 'c005@sustainx.com',  'hashed_pw');


-- ============================================================
-- 8. SEED DATA — Meters
-- ============================================================
INSERT INTO meters (meter_id, user_id) VALUES
  ('M001', 'PR001'), ('M002', 'PR002'), ('M003', 'PR003'),
  ('M004', 'PR004'), ('M005', 'PR005'), ('M006', 'C001'),
  ('M007', 'C002'),  ('M008', 'C003'),  ('M009', 'C004'),
  ('M010', 'C005'),  ('M011', 'PR006'), ('M012', 'PR007'),
  ('M013', 'PR008'), ('M014', 'PR009'), ('M015', 'PR010');


-- ============================================================
-- 9. SEED DATA — Energy Readings (Cycles 1 & 2)
-- ============================================================
INSERT INTO energy_readings (user_id, meter_id, import_kwh, export_kwh, billing_cycle) VALUES
  -- Cycle 1
  ('PR001','M001', 5, 25, 1), ('PR002','M002', 6, 28, 1),
  ('PR003','M003', 4, 22, 1), ('PR004','M004', 3, 20, 1),
  ('PR005','M005', 5, 30, 1), ('C001', 'M006',30,  0, 1),
  ('C002', 'M007',35,  0, 1), ('C003', 'M008',28,  0, 1),
  ('C004', 'M009',40,  0, 1), ('C005', 'M010',32,  0, 1),
  ('PR006','M011',10, 15, 1), ('PR007','M012',18, 12, 1),
  ('PR008','M013',12, 14, 1), ('PR009','M014',20, 10, 1),
  ('PR010','M015',15, 16, 1),

  -- Cycle 2
  ('PR001','M001', 6, 27, 2), ('PR002','M002', 5, 30, 2),
  ('PR003','M003', 4, 24, 2), ('PR004','M004', 3, 22, 2),
  ('PR005','M005', 6, 32, 2), ('C001', 'M006',32,  0, 2),
  ('C002', 'M007',36,  0, 2), ('C003', 'M008',30,  0, 2),
  ('C004', 'M009',42,  0, 2), ('C005', 'M010',34,  0, 2),
  ('PR006','M011',11, 16, 2), ('PR007','M012',20, 13, 2),
  ('PR008','M013',13, 15, 2), ('PR009','M014',22, 11, 2),
  ('PR010','M015',16, 18, 2);


-- ============================================================
-- 10. SEED DATA — Wallets (one per user)
-- ============================================================
INSERT INTO wallets (user_id) VALUES
  ('PR001'),('PR002'),('PR003'),('PR004'),('PR005'),
  ('PR006'),('PR007'),('PR008'),('PR009'),('PR010'),
  ('C001'), ('C002'), ('C003'), ('C004'), ('C005');


-- ============================================================
-- 11. COIN GENERATION PROCEDURE
--     Call this after each billing cycle is uploaded.
--     Logic:
--       net = export - import
--       if net > 0  → prosumer surplus
--           yellow += net × yellow_rate   (minted; auto-offsets red debt)
--           green   = 0                   (NOT minted from energy)
--           red     = 0
--       if net <= 0 → net consumer / net-deficit prosumer
--           yellow  = 0
--           green   = 0
--           red    += ABS(net) × red_rate (grid consumption debt)
-- ============================================================
DELIMITER $$

CREATE PROCEDURE generate_coins_for_cycle(
    IN p_billing_cycle INT,
    IN p_yellow_rate   DECIMAL(5,3),
    IN p_red_rate      DECIMAL(5,3)
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

    -- Step 3: Auto-offset yellow vs red and then green vs red
    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_offsets (
        user_id VARCHAR(10),
        offset_amount DECIMAL(10,4),
        coin_type ENUM('yellow','green')
    );
    TRUNCATE TABLE tmp_offsets;

    -- Yellow offsets first
    INSERT INTO tmp_offsets (user_id, offset_amount, coin_type)
    SELECT w.user_id, LEAST(w.yellow_coins, w.red_coins), 'yellow'
    FROM wallets w
    WHERE w.yellow_coins > 0
      AND w.red_coins > 0
      AND w.user_id IN (
          SELECT user_id FROM coin_generation_log WHERE billing_cycle = p_billing_cycle
      );

    UPDATE wallets w
    JOIN tmp_offsets t ON w.user_id = t.user_id AND t.coin_type = 'yellow'
    SET
        w.yellow_coins = w.yellow_coins - t.offset_amount,
        w.red_coins    = w.red_coins    - t.offset_amount,
        w.updated_at   = CURRENT_TIMESTAMP;

    INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, billing_cycle, note, status)
    SELECT
        t.user_id, NULL, 'yellow', t.offset_amount, 'offset', p_billing_cycle,
        CONCAT('Auto-offset cycle ', p_billing_cycle, ' (yellow)'), 'completed'
    FROM tmp_offsets t
    WHERE t.offset_amount > 0 AND t.coin_type = 'yellow';

    TRUNCATE TABLE tmp_offsets;

    -- Green offsets next
    INSERT INTO tmp_offsets (user_id, offset_amount, coin_type)
    SELECT w.user_id, LEAST(w.green_coins, w.red_coins), 'green'
    FROM wallets w
    WHERE w.green_coins > 0
      AND w.red_coins > 0
      AND w.user_id IN (
          SELECT user_id FROM coin_generation_log WHERE billing_cycle = p_billing_cycle
      );

    UPDATE wallets w
    JOIN tmp_offsets t ON w.user_id = t.user_id AND t.coin_type = 'green'
    SET
        w.green_coins = w.green_coins - t.offset_amount,
        w.red_coins   = w.red_coins   - t.offset_amount,
        w.updated_at  = CURRENT_TIMESTAMP;

    INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, billing_cycle, note, status)
    SELECT
        t.user_id, NULL, 'green', t.offset_amount, 'offset', p_billing_cycle,
        CONCAT('Auto-offset cycle ', p_billing_cycle, ' (green)'), 'completed'
    FROM tmp_offsets t
    WHERE t.offset_amount > 0 AND t.coin_type = 'green';

    DROP TEMPORARY TABLE IF EXISTS tmp_offsets;
END$$

DELIMITER ;

-- Run coin generation for both cycles:
-- CALL generate_coins_for_cycle(1);
-- CALL generate_coins_for_cycle(2);


-- ============================================================
-- 12a. TRANSFER PROCEDURE  (Green coins only — wallet-to-wallet)
--      Used when a user sends green coins they already hold to another user.
-- ============================================================
DELIMITER $$

CREATE PROCEDURE transfer_green_coins(
    IN p_sender_id   VARCHAR(10),
    IN p_receiver_id VARCHAR(10),
    IN p_amount      DECIMAL(10,4),
    IN p_note        VARCHAR(255)
)
BEGIN
    DECLARE sender_balance DECIMAL(10,4);

    SELECT green_coins INTO sender_balance
    FROM wallets WHERE user_id = p_sender_id FOR UPDATE;

    IF sender_balance < p_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient green coin balance';
    END IF;

    UPDATE wallets SET green_coins = green_coins - p_amount, updated_at = NOW()
    WHERE user_id = p_sender_id;

    UPDATE wallets SET green_coins = green_coins + p_amount, updated_at = NOW()
    WHERE user_id = p_receiver_id;

    INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, note, status)
    VALUES (p_sender_id, p_receiver_id, 'green', p_amount, 'transfer', p_note, 'completed');
END$$

DELIMITER ;


-- ============================================================
-- 12b. SELL YELLOW COINS  (Yellow → Green marketplace sale)
--      Prosumer sells yellow coins; buyer receives green coins.
--      Caller must pre-calculate p_green_amount using:
--        green = (yellow × YELLOW_VALUE × (1 - PLATFORM_FEE)) / GREEN_VALUE
--        e.g.  green = (yellow × 4 × 0.80) / 7
-- ============================================================
DELIMITER $$

CREATE PROCEDURE sell_yellow_coins(
    IN p_seller_id     VARCHAR(10),
    IN p_buyer_id      VARCHAR(10),
    IN p_yellow_amount DECIMAL(10,4),
    IN p_green_amount  DECIMAL(10,4),
    IN p_gross_rs      DECIMAL(10,2),   -- full Rs value sent by seller
    IN p_profit_rs     DECIMAL(10,2)    -- platform commission (Rs)
)
BEGIN
    DECLARE yellow_bal DECIMAL(10,4);

    SELECT yellow_coins INTO yellow_bal
    FROM wallets WHERE user_id = p_seller_id FOR UPDATE;

    IF yellow_bal < p_yellow_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient yellow coin balance';
    END IF;

    -- Deduct yellow from seller
    UPDATE wallets SET yellow_coins = yellow_coins - p_yellow_amount, updated_at = NOW()
    WHERE user_id = p_seller_id;

    -- Credit green to buyer
    UPDATE wallets SET green_coins = green_coins + p_green_amount, updated_at = NOW()
    WHERE user_id = p_buyer_id;

    -- Log seller's side: yellow deducted (full Rs value)
    INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, amount_rs, transaction_type, note, status)
    VALUES (p_seller_id, p_buyer_id, 'yellow', p_yellow_amount, p_gross_rs, 'sale',
            CONCAT('Sent Rs ', p_gross_rs, ' of energy (', p_yellow_amount, ' yellow coins)'), 'completed');

    -- Log buyer's side: green credited (net Rs value after platform fee)
    INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, amount_rs, transaction_type, note, status)
    VALUES (p_seller_id, p_buyer_id, 'green', p_green_amount, p_gross_rs - p_profit_rs, 'purchase',
            CONCAT('Received Rs ', p_gross_rs - p_profit_rs, ' of energy (', p_green_amount, ' green coins)'), 'completed');

    -- Record admin profit
    INSERT INTO admin_profit (seller_id, buyer_id, yellow_sold, gross_rs, profit_rs, buyer_green)
    VALUES (p_seller_id, p_buyer_id, p_yellow_amount, p_gross_rs, p_profit_rs, p_green_amount);
END$$

DELIMITER ;


-- ============================================================
-- 13. OFFSET PROCEDURE  (Use yellow coins to cancel red coins)
--     Yellow coins offset red at 1:1 ratio.
--     Called automatically after coin generation, or manually by user.
-- ============================================================
DELIMITER $$

CREATE PROCEDURE offset_red_with_yellow(
    IN p_user_id VARCHAR(10),
    IN p_amount  DECIMAL(10,4)
)
BEGIN
    DECLARE yellow_bal DECIMAL(10,4);
    DECLARE red_bal    DECIMAL(10,4);

    SELECT yellow_coins, red_coins INTO yellow_bal, red_bal
    FROM wallets WHERE user_id = p_user_id FOR UPDATE;

    IF yellow_bal < p_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Not enough yellow coins to offset';
    END IF;

    IF red_bal < p_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Offset amount exceeds red coin balance';
    END IF;

    UPDATE wallets
    SET yellow_coins = yellow_coins - p_amount,
        red_coins    = red_coins    - p_amount,
        updated_at   = NOW()
    WHERE user_id = p_user_id;

    INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, note, status)
    VALUES (p_user_id, NULL, 'yellow', p_amount, 'offset', 'Red debt offset with yellow coins', 'completed');
END$$

DELIMITER ;


-- ============================================================
-- 14. USEFUL VIEWS FOR YOUR BACKEND / API
-- ============================================================

-- Full wallet overview per user
CREATE VIEW vw_wallet_overview AS
SELECT
    u.user_id,
    u.user_type,
    u.name,
    w.yellow_coins,
    w.green_coins,
    w.red_coins,
    w.updated_at
FROM users u
JOIN wallets w ON u.user_id = w.user_id;


-- Per-cycle coin breakdown (great for charts)
CREATE VIEW vw_cycle_coin_summary AS
SELECT
    cgl.billing_cycle,
    cgl.user_id,
    u.user_type,
    cgl.import_kwh,
    cgl.export_kwh,
    cgl.net_kwh,
    cgl.yellow_coins_minted,
    cgl.green_coins_minted,
    cgl.red_coins_minted
FROM coin_generation_log cgl
JOIN users u ON cgl.user_id = u.user_id;


-- Top contributors (Yellow coin leaderboard)
CREATE VIEW vw_top_contributors AS
SELECT
    u.user_id,
    u.name,
    w.yellow_coins AS total_yellow,
    w.green_coins  AS available_green,
    w.red_coins    AS grid_debt
FROM wallets w
JOIN users u ON u.user_id = w.user_id
ORDER BY w.yellow_coins DESC;


-- Transaction history per user
CREATE VIEW vw_transaction_history AS
SELECT
    t.transaction_id,
    t.transaction_type,
    t.coin_type,
    t.amount,
    t.amount_rs,
    t.sender_id,
    s.name   AS sender_name,
    t.receiver_id,
    r.name   AS receiver_name,
    t.billing_cycle,
    t.note,
    t.status,
    t.created_at
FROM transactions t
LEFT JOIN users s ON s.user_id = t.sender_id
LEFT JOIN users r ON r.user_id = t.receiver_id;


-- ============================================================
-- 13b. OFFSET PROCEDURE  (Use green coins to cancel red — fallback after yellow)
-- ============================================================
DELIMITER $$

CREATE PROCEDURE offset_red_with_green(
    IN p_user_id VARCHAR(10),
    IN p_amount  DECIMAL(10,4)
)
BEGIN
    DECLARE green_bal DECIMAL(10,4);
    DECLARE red_bal   DECIMAL(10,4);

    SELECT green_coins, red_coins INTO green_bal, red_bal
    FROM wallets WHERE user_id = p_user_id FOR UPDATE;

    IF green_bal < p_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Not enough green coins to offset';
    END IF;

    IF red_bal < p_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Offset amount exceeds red coin balance';
    END IF;

    UPDATE wallets
    SET green_coins = green_coins - p_amount,
        red_coins   = red_coins   - p_amount,
        updated_at  = NOW()
    WHERE user_id = p_user_id;

    INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, note, status)
    VALUES (p_user_id, NULL, 'green', p_amount, 'offset', 'Red debt offset with green coins', 'completed');
END$$

DELIMITER ;


-- ============================================================
-- 16. COIN VALUES  (monetary Rs value per coin type — source of truth)
-- ============================================================
CREATE TABLE coin_values (
    coin_type   ENUM('yellow', 'green', 'red') PRIMARY KEY,
    value_rs    DECIMAL(10,2)  NOT NULL,
    description VARCHAR(150),
    updated_at  TIMESTAMP      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO coin_values (coin_type, value_rs, description) VALUES
    ('yellow', 4.00,  '1 yellow coin = Rs 4  — earned by prosumers from surplus kWh'),
    ('green',  7.00,  '1 green coin  = Rs 7  — tradeable currency from marketplace or P2P sale'),
    ('red',    10.00, '1 red coin    = Rs 10 — grid consumption debt penalty');


-- ============================================================
-- 17. ADMIN PROFIT  (platform commission log for yellow→green sales)
-- ============================================================
CREATE TABLE admin_profit (
    profit_id   INT           AUTO_INCREMENT PRIMARY KEY,
    seller_id   VARCHAR(10)   NOT NULL,
    buyer_id    VARCHAR(10)   NOT NULL,
    yellow_sold DECIMAL(10,4) NOT NULL,   -- yellow coins deducted from seller
    gross_rs    DECIMAL(10,2) NOT NULL,   -- full Rs value of the sale
    profit_rs   DECIMAL(10,2) NOT NULL,   -- platform commission (gross × fee%)
    buyer_green DECIMAL(10,4) NOT NULL,   -- green coins credited to buyer
    created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (seller_id) REFERENCES users(user_id),
    FOREIGN KEY (buyer_id)  REFERENCES users(user_id)
);


-- ============================================================
-- MIGRATION  (run these on an existing database)
-- ============================================================
-- ALTER TABLE transactions ADD COLUMN amount_rs DECIMAL(10,2) DEFAULT NULL AFTER amount;
-- ALTER TABLE transactions MODIFY COLUMN coin_type ENUM('green','red','yellow') NOT NULL;
-- ALTER TABLE transactions MODIFY COLUMN transaction_type ENUM('mint','transfer','offset','sale','purchase','burn') NOT NULL;


-- ============================================================
-- 15. HANDY QUERIES FOR YOUR API ENDPOINTS
-- ============================================================

-- GET wallet for one user
-- SELECT * FROM vw_wallet_overview WHERE user_id = 'PR001';

-- GET transaction history for one user
-- SELECT * FROM vw_transaction_history
-- WHERE sender_id = 'PR001' OR receiver_id = 'PR001'
-- ORDER BY created_at DESC;

-- GET all prosumers with yellow coins available to sell
-- SELECT user_id, name, yellow_coins FROM vw_wallet_overview
-- WHERE user_type = 'prosumer' AND yellow_coins > 0
-- ORDER BY yellow_coins DESC;

-- GET all users with grid debt (red > 0) — targets for offsetting
-- SELECT user_id, name, red_coins FROM vw_wallet_overview
-- WHERE red_coins > 0
-- ORDER BY red_coins DESC;

-- GET cycle summary for charts
-- SELECT * FROM vw_cycle_coin_summary WHERE billing_cycle = 1;

-- GET system-wide coin totals
-- SELECT
--     SUM(yellow_coins) AS total_yellow,
--     SUM(green_coins)  AS total_green,
--     SUM(red_coins)    AS total_red
-- FROM wallets;