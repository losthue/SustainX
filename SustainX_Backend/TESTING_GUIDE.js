/**
 * EnergyPass Backend - Quick Start & Testing Guide
 * 
 * This file contains instructions and example requests for testing the API
 */

// ==============================================================
// 1. START THE SERVER
// ==============================================================

/**
 * Development Mode (with auto-reload):
 * npm run dev
 * 
 * Production Mode:
 * npm start
 * 
 * Server will be available at http://localhost:5000
 */

// ==============================================================
// 2. POSTMAN COLLECTION - Example Requests
// ==============================================================

/**
 * SETUP:
 * 1. Install Postman: https://www.postman.com/downloads/
 * 2. Create a new Collection called "EnergyPass Backend"
 * 3. Add a variable "token" to store JWT tokens
 * 4. Add a variable "baseUrl" = http://localhost:5000/api
 * 5. Add a variable "userId" to store user IDs
 */

// ==============================================================
// 3. AUTHENTICATION FLOW
// ==============================================================

/**
 * Step 1: Register a New User
 * 
 * POST http://localhost:5000/api/auth/register
 * Content-Type: application/json
 * 
 * Request Body:
 * {
 *   "username": "john_doe",
 *   "email": "john@example.com",
 *   "password": "SecurePass123",
 *   "fullName": "John Doe"
 * }
 * 
 * Expected Response (201):
 * {
 *   "success": true,
 *   "message": "User registered successfully",
 *   "user": {
 *     "id": "USER_ID",
 *     "username": "john_doe",
 *     "email": "john@example.com",
 *     "walletAddress": "wallet_USER_ID_TIMESTAMP"
 *   },
 *   "token": "JWT_TOKEN"
 * }
 * 
 * Save the token and userId for next requests
 */

/**
 * Step 2: Login User
 * 
 * POST http://localhost:5000/api/auth/login
 * Content-Type: application/json
 * 
 * Request Body:
 * {
 *   "email": "john@example.com",
 *   "password": "SecurePass123"
 * }
 * 
 * Expected Response (200):
 * {
 *   "success": true,
 *   "message": "Login successful",
 *   "user": {...},
 *   "token": "JWT_TOKEN"
 * }
 */

/**
 * Step 3: Get User Profile
 * 
 * GET http://localhost:5000/api/auth/profile
 * Authorization: Bearer JWT_TOKEN
 * 
 * Expected Response (200):
 * {
 *   "success": true,
 *   "data": {
 *     "userId": "USER_ID",
 *     "username": "john_doe",
 *     "walletAddress": "wallet_...",
 *     "balances": {
 *       "yellowCoins": 0,
 *       "greenCoins": 0,
 *       "redCoins": 0
 *     },
 *     "totalBalance": 0,
 *     "energyScore": 0
 *   }
 * }
 */

// ==============================================================
// 4. ENERGY DATA FLOW
// ==============================================================

/**
 * Record Energy Data (Import/Export)
 * 
 * POST http://localhost:5000/api/energy/record
 * Authorization: Bearer JWT_TOKEN
 * Content-Type: application/json
 * 
 * Request Body:
 * {
 *   "importedKWh": 10,
 *   "exportedKWh": 25,
 *   "conversionRate": 10
 * }
 * 
 * Expected Response (201):
 * {
 *   "success": true,
 *   "message": "Energy data processed successfully",
 *   "energyData": {
 *     "importedKWh": 10,
 *     "exportedKWh": 25,
 *     "netEnergy": 15,
 *     "coinsGenerated": {
 *       "yellowCoins": 250,
 *       "greenCoins": 150,
 *       "redCoins": 0
 *     }
 *   },
 *   "userWallet": {
 *     "yellowCoins": 250,
 *     "greenCoins": 150,
 *     "redCoins": 0,
 *     "totalBalance": 400,
 *     "energyScore": 40
 *   }
 * }
 */

/**
 * Get Energy History
 * 
 * GET http://localhost:5000/api/energy/history?limit=30
 * Authorization: Bearer JWT_TOKEN
 * 
 * Expected Response (200): Array of energy records
 */

/**
 * Get Energy Statistics
 * 
 * GET http://localhost:5000/api/energy/stats?days=30
 * Authorization: Bearer JWT_TOKEN
 * 
 * Expected Response (200):
 * {
 *   "success": true,
 *   "period": "30 days",
 *   "data": {
 *     "totalImported": 100,
 *     "totalExported": 250,
 *     "totalYellowCoins": 2500,
 *     "totalGreenCoins": 1500,
 *     "totalRedCoins": 0,
 *     "averageNetEnergy": 15,
 *     "dataPoints": 10
 *   }
 * }
 */

// ==============================================================
// 5. WALLET & LEADERBOARD
// ==============================================================

/**
 * Get Wallet Information
 * 
 * GET http://localhost:5000/api/wallet/info
 * Authorization: Bearer JWT_TOKEN
 */

/**
 * Get Wallet Balance
 * 
 * GET http://localhost:5000/api/wallet/balance
 * Authorization: Bearer JWT_TOKEN
 */

/**
 * Generate QR Code
 * 
 * GET http://localhost:5000/api/wallet/qr-code
 * Authorization: Bearer JWT_TOKEN
 * 
 * Expected Response (200):
 * {
 *   "success": true,
 *   "data": {
 *     "qrCodeUrl": "data:image/png;base64,...",
 *     "walletAddress": "wallet_...",
 *     "username": "john_doe"
 *   }
 * }
 */

/**
 * Get Leaderboard (Top Users by Energy Score)
 * 
 * GET http://localhost:5000/api/wallet/leaderboard?limit=10
 * Authorization: Bearer JWT_TOKEN
 */

/**
 * Get User Rank
 * 
 * GET http://localhost:5000/api/wallet/rank
 * Authorization: Bearer JWT_TOKEN
 */

// ==============================================================
// 6. TRANSACTIONS & TRANSFERS
// ==============================================================

/**
 * Create Two Users First (for transfer testing)
 * Register User 2 with email: jane@example.com
 * Save User 2's ID as USER_ID_2
 */

/**
 * Transfer Coins Between Users
 * 
 * POST http://localhost:5000/api/transactions/transfer
 * Authorization: Bearer JWT_TOKEN
 * Content-Type: application/json
 * 
 * Request Body:
 * {
 *   "toUserId": "USER_ID_2",
 *   "yellowCoins": 50,
 *   "greenCoins": 25,
 *   "redCoins": 10,
 *   "note": "Payment for energy services"
 * }
 * 
 * Expected Response (201):
 * {
 *   "success": true,
 *   "message": "Transfer completed successfully",
 *   "transaction": {
 *     "transactionId": "TRANSACTION_ID",
 *     "from": "john_doe",
 *     "to": "jane_doe",
 *     "coinsTransferred": {
 *       "yellow": 50,
 *       "green": 25,
 *       "red": 10
 *     },
 *     "totalAmount": 85,
 *     "timestamp": "2024-01-15T10:30:00Z"
 *   },
 *   "senderBalance": {...},
 *   "receiverBalance": {...}
 * }
 */

/**
 * Get Transaction History
 * 
 * GET http://localhost:5000/api/transactions/history?limit=50
 * Authorization: Bearer JWT_TOKEN
 */

/**
 * Get Sent Transactions
 * 
 * GET http://localhost:5000/api/transactions/sent?limit=30
 * Authorization: Bearer JWT_TOKEN
 */

/**
 * Get Received Transactions
 * 
 * GET http://localhost:5000/api/transactions/received?limit=30
 * Authorization: Bearer JWT_TOKEN
 */

/**
 * Get Transaction Statistics
 * 
 * GET http://localhost:5000/api/transactions/stats
 * Authorization: Bearer JWT_TOKEN
 */

// ==============================================================
// 7. TESTING CHECKLIST
// ==============================================================

/**
 * ✅ Authentication Tests:
 *    - [ ] POST /auth/register - Create new user
 *    - [ ] POST /auth/login - Login with email/password
 *    - [ ] GET /auth/profile - Get user profile
 *    - [ ] PUT /auth/profile - Update profile
 * 
 * ✅ Wallet Tests:
 *    - [ ] GET /wallet/info - Get wallet information
 *    - [ ] GET /wallet/balance - Get current balance
 *    - [ ] GET /wallet/qr-code - Generate QR code
 *    - [ ] GET /wallet/leaderboard - Get top users
 *    - [ ] GET /wallet/rank - Get user's rank
 * 
 * ✅ Energy Tests:
 *    - [ ] POST /energy/record - Record energy data
 *    - [ ] GET /energy/history - Get energy history
 *    - [ ] GET /energy/stats - Get statistics
 * 
 * ✅ Transaction Tests:
 *    - [ ] POST /transactions/transfer - Transfer coins
 *    - [ ] GET /transactions/history - Get history
 *    - [ ] GET /transactions/sent - Get sent transactions
 *    - [ ] GET /transactions/received - Get received transactions
 *    - [ ] GET /transactions/stats - Get statistics
 * 
 * ✅ Error Tests:
 *    - [ ] Test with missing token
 *    - [ ] Test with invalid credentials
 *    - [ ] Test with insufficient balance
 *    - [ ] Test with invalid amounts
 *    - [ ] Test with non-existent user
 */

// ==============================================================
// 8. COMMON ERRORS & SOLUTIONS
// ==============================================================

/**
 * Error: "MongoDB connection failed"
 * Solution: Ensure MongoDB is running on localhost:27017
 *          Or update MONGODB_URI in .env
 * 
 * Error: "Cannot find module"
 * Solution: Run: npm install
 * 
 * Error: "Port 5000 already in use"
 * Solution: Change PORT in .env or kill the process on port 5000
 * 
 * Error: "Invalid token"
 * Solution: Ensure you're using the correct JWT token
 *          Check if token has expired
 * 
 * Error: "Insufficient balance"
 * Solution: Record energy data first to generate coins
 *          Check current balance with GET /wallet/balance
 */

// ==============================================================
// 9. USEFUL COMMANDS
// ==============================================================

/**
 * Install dependencies:
 * npm install
 * 
 * Start development server:
 * npm run dev
 * 
 * Start production server:
 * npm start
 * 
 * Check Node version:
 * node --version
 * 
 * Check npm version:
 * npm --version
 */

// ==============================================================
// 10. HEALTH CHECK
// ==============================================================

/**
 * Check if server is running:
 * 
 * GET http://localhost:5000/health
 * 
 * Expected Response (200):
 * {
 *   "status": "OK",
 *   "message": "EnergyPass Backend is running",
 *   "timestamp": "2024-01-15T10:30:00.000Z",
 *   "database": "connected"
 * }
 */

module.exports = {
    message: "This file contains testing documentation. See comments for API examples."
};
