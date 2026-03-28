-- Purchases table for Stripe coin purchases
CREATE TABLE IF NOT EXISTS purchases (
    purchase_id       INT AUTO_INCREMENT PRIMARY KEY,
    user_id           VARCHAR(10) NOT NULL,
    package_id        VARCHAR(20) NOT NULL,
    package_name      VARCHAR(50) NOT NULL,
    coin_amount       INT NOT NULL,
    bonus_amount      INT NOT NULL DEFAULT 0,
    total_coins       INT NOT NULL,
    price_cents       INT NOT NULL,
    currency          VARCHAR(3) NOT NULL DEFAULT 'MUR',
    stripe_session_id VARCHAR(255) NULL,
    stripe_payment_id VARCHAR(255) NULL,
    status            ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at      TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Index for fast lookups
CREATE INDEX idx_purchases_user ON purchases(user_id);
CREATE INDEX idx_purchases_stripe ON purchases(stripe_session_id);
