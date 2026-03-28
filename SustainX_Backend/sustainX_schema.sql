-- ============================================================
--  SustainX Innovation Challenge 2026
--  Database Schema — Energy Wallet System
--  Coin Logic:
--    🟡 Yellow  = Export - Import (net contribution, display only)
--    🟢 Green   = Solar energy available for transfer/use
--    🔴 Red     = Grid consumption (import > export; user wants 0)
-- ============================================================


-- ============================================================
-- 1. USERS
-- ============================================================
CREATE TABLE users (
    user_id       VARCHAR(10)  PRIMARY KEY,
    user_type     ENUM('prosumer', 'consumer') NOT NULL,
    name          VARCHAR(100),
    email         VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active     BOOLEAN      DEFAULT TRUE,
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
    coin_type        ENUM('green', 'red') NOT NULL,        -- Yellow cannot be transferred
    amount           DECIMAL(10,4) NOT NULL CHECK (amount > 0),

    transaction_type ENUM(
        'mint',       -- system creates coins after reading
        'transfer',   -- user sends green to another user
        'offset',     -- green coins used to cancel red coins
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
--           yellow += net   (display only, contribution badge)
--           green  += net   (spendable solar value)
--           red    = 0      (no grid debt)
--       if net <= 0 → net consumer
--           yellow = 0
--           green  = 0
--           red    += ABS(net)  (grid consumption debt)
-- ============================================================
DELIMITER $$

CREATE PROCEDURE generate_coins_for_cycle(IN p_billing_cycle INT)
BEGIN
    -- Insert generation log for this cycle
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
        -- 🟡 Yellow: net surplus only, display badge
        CASE WHEN net_kwh > 0 THEN net_kwh ELSE 0 END,
        -- 🟢 Green: same as yellow — surplus becomes tradeable solar value
        CASE WHEN net_kwh > 0 THEN net_kwh ELSE 0 END,
        -- 🔴 Red: grid debt when consuming more than producing
        CASE WHEN net_kwh < 0 THEN ABS(net_kwh) ELSE 0 END
    FROM energy_readings
    WHERE billing_cycle = p_billing_cycle
    ON DUPLICATE KEY UPDATE
        yellow_coins_minted = VALUES(yellow_coins_minted),
        green_coins_minted  = VALUES(green_coins_minted),
        red_coins_minted    = VALUES(red_coins_minted);

    -- Update wallet balances
    UPDATE wallets w
    JOIN coin_generation_log cgl
        ON w.user_id = cgl.user_id
       AND cgl.billing_cycle = p_billing_cycle
    SET
        w.yellow_coins = w.yellow_coins + cgl.yellow_coins_minted,
        w.green_coins  = w.green_coins  + cgl.green_coins_minted,
        w.red_coins    = w.red_coins    + cgl.red_coins_minted,
        w.updated_at   = CURRENT_TIMESTAMP;

    -- Log mint transactions (green coins only — yellow is display, red is debt)
    INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, billing_cycle, note, status)
    SELECT
        NULL,
        cgl.user_id,
        'green',
        cgl.green_coins_minted,
        'mint',
        p_billing_cycle,
        CONCAT('Auto-mint cycle ', p_billing_cycle),
        'completed'
    FROM coin_generation_log cgl
    WHERE cgl.billing_cycle = p_billing_cycle
      AND cgl.green_coins_minted > 0;
END$$

DELIMITER ;

-- Run coin generation for both cycles:
-- CALL generate_coins_for_cycle(1);
-- CALL generate_coins_for_cycle(2);


-- ============================================================
-- 12. TRANSFER PROCEDURE  (Green coins only)
--     Validates balance before executing.
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

    -- Lock sender row
    SELECT green_coins INTO sender_balance
    FROM wallets
    WHERE user_id = p_sender_id
    FOR UPDATE;

    IF sender_balance < p_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient green coin balance';
    END IF;

    -- Deduct from sender
    UPDATE wallets SET green_coins = green_coins - p_amount, updated_at = NOW()
    WHERE user_id = p_sender_id;

    -- Credit receiver
    UPDATE wallets SET green_coins = green_coins + p_amount, updated_at = NOW()
    WHERE user_id = p_receiver_id;

    -- Log transaction
    INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, note, status)
    VALUES (p_sender_id, p_receiver_id, 'green', p_amount, 'transfer', p_note, 'completed');
END$$

DELIMITER ;


-- ============================================================
-- 13. OFFSET PROCEDURE  (Use green coins to cancel red coins)
--     A consumer buys green coins from the market to reduce their red balance.
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
    VALUES (p_user_id, NULL, 'green', p_amount, 'offset', 'Red coin offset', 'completed');
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
-- 15. HANDY QUERIES FOR YOUR API ENDPOINTS
-- ============================================================

-- GET wallet for one user
-- SELECT * FROM vw_wallet_overview WHERE user_id = 'PR001';

-- GET transaction history for one user
-- SELECT * FROM vw_transaction_history
-- WHERE sender_id = 'PR001' OR receiver_id = 'PR001'
-- ORDER BY created_at DESC;

-- GET all prosumers with surplus (have green coins to offer)
-- SELECT user_id, name, green_coins FROM vw_wallet_overview
-- WHERE user_type = 'prosumer' AND green_coins > 0
-- ORDER BY green_coins DESC;

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