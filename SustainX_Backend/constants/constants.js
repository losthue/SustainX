// Coin Types
const COIN_TYPES = {
    YELLOW: 'yellow',      // Energy Contribution
    GREEN: 'green',        // Usable Shared Energy
    RED: 'red'             // Energy Consumption
};

// Transaction Types
const TRANSACTION_TYPES = {
    TRANSFER: 'transfer',
    CONVERSION: 'conversion',
    REWARD: 'reward',
    PURCHASE: 'purchase',
    REDEEM: 'redeem'
};

// Transaction Status
const TRANSACTION_STATUS = {
    PENDING: 'pending',
    COMPLETED: 'completed',
    FAILED: 'failed',
    CANCELLED: 'cancelled'
};

// Energy Data Status
const ENERGY_DATA_STATUS = {
    PENDING: 'pending',
    VERIFIED: 'verified',
    PROCESSED: 'processed',
    ARCHIVED: 'archived'
};

// Data Sources
const DATA_SOURCES = {
    SMART_METER: 'smart_meter',
    MANUAL_ENTRY: 'manual_entry',
    API_INTEGRATION: 'api_integration',
    HISTORICAL: 'historical'
};

// Conversion Rates and Constants
const ENERGY_CONSTANTS = {
    DEFAULT_CONVERSION_RATE: 10,  // 1 kWh = 10 coins
    DEFAULT_LEADERBOARD_LIMIT: 10,
    ENERGY_SCORE_EXPORT_BONUS: 1,  // 1 point per kWh exported
    ENERGY_SCORE_TRANSFER_BONUS_SENDER: 5,
    ENERGY_SCORE_TRANSFER_BONUS_RECEIVER: 10
};

// Validation Constants
const VALIDATION = {
    MIN_USERNAME_LENGTH: 3,
    MAX_USERNAME_LENGTH: 50,
    MIN_PASSWORD_LENGTH: 6,
    MAX_PASSWORD_LENGTH: 100,
    MIN_TRANSFER_AMOUNT: 1,
    MAX_TRANSFER_AMOUNT: 1000000
};

// Error Messages
const ERROR_MESSAGES = {
    INSUFFICIENT_BALANCE: 'Insufficient balance',
    USER_NOT_FOUND: 'User not found',
    INVALID_CREDENTIALS: 'Invalid email or password',
    TOKEN_EXPIRED: 'Token expired',
    UNAUTHORIZED: 'Unauthorized access',
    INVALID_INPUT: 'Invalid input provided',
    DUPLICATE_USER: 'Username or email already exists',
    TRANSACTION_FAILED: 'Transaction failed'
};

// Success Messages
const SUCCESS_MESSAGES = {
    REGISTERED: 'User registered successfully',
    LOGIN_SUCCESS: 'Login successful',
    TRANSFER_COMPLETE: 'Transfer completed successfully',
    DATA_RECORDED: 'Energy data recorded successfully',
    PROFILE_UPDATED: 'Profile updated successfully'
};

module.exports = {
    COIN_TYPES,
    TRANSACTION_TYPES,
    TRANSACTION_STATUS,
    ENERGY_DATA_STATUS,
    DATA_SOURCES,
    ENERGY_CONSTANTS,
    VALIDATION,
    ERROR_MESSAGES,
    SUCCESS_MESSAGES
};
