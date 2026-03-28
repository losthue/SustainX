const express = require('express');
const router = express.Router();
const WalletController = require('../controllers/WalletController');
const { authMiddleware } = require('../middleware/auth');

// All wallet routes require authentication
router.use(authMiddleware);

// Wallet info & balance
router.get('/info', WalletController.getWallet);
router.get('/balance', WalletController.getBalance);

// Green coin transfer
router.post('/transfer-green', WalletController.transferGreen);

// Offset red coins with green
router.post('/offset-red', WalletController.offsetRed);

// Leaderboard
router.get('/leaderboard', WalletController.getLeaderboard);

// System-wide totals
router.get('/system-totals', WalletController.getSystemTotals);

module.exports = router;
