const express = require('express');
const router = express.Router();
const WalletController = require('../controllers/WalletController');
const { authMiddleware } = require('../middleware/auth');

// All wallet routes require authentication
router.use(authMiddleware);

// Wallet endpoints
router.get('/info', WalletController.getWallet);
router.get('/balance', WalletController.getBalance);
router.get('/address', WalletController.getWalletAddress);

// QR Code generation
router.get('/qr-code', WalletController.generateQRCode);

// Leaderboard endpoints (public, but included here for wallet context)
router.get('/leaderboard', WalletController.getLeaderboard);
router.get('/leaderboard/coins', WalletController.getLeaderboardByCoins);
router.get('/rank', WalletController.getUserRank);

module.exports = router;
