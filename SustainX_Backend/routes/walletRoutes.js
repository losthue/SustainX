const express = require('express');
const router = express.Router();
const WalletController = require('../controllers/WalletController');
const { authMiddleware } = require('../middleware/auth');

// All wallet routes require authentication
router.use(authMiddleware);

// Wallet info & balance
router.get('/info', WalletController.getWallet);
router.get('/balance', WalletController.getBalance);

// Coin monetary values (yellow Rs4, green Rs7, red Rs10, platform fee 20%)
router.get('/coin-values', WalletController.getCoinValues);

// P2P energy sale: prosumer sends Rs amount → yellow deducted, buyer gets green, admin keeps spread
router.post('/send-energy', WalletController.sendEnergy);

// P2P marketplace: prosumer sells yellow coins (by coin count) → buyer receives green coins
router.post('/sell-yellow', WalletController.sellYellow);

// Green coin wallet-to-wallet transfer
router.post('/transfer-green', WalletController.transferGreen);

// Manual offset: burn yellow coins to cancel red debt
router.post('/offset-red', WalletController.offsetRed);

// Leaderboard
router.get('/leaderboard', WalletController.getLeaderboard);

// System-wide totals
router.get('/system-totals', WalletController.getSystemTotals);

module.exports = router;
