const express = require('express');
const router = express.Router();
const TransactionController = require('../controllers/TransactionController');
const { authMiddleware } = require('../middleware/auth');

// All transaction routes require authentication
router.use(authMiddleware);

// Transaction endpoints
router.post('/transfer', TransactionController.transferCoins);
router.get('/history', TransactionController.getTransactionHistory);
router.get('/stats', TransactionController.getTransactionStats);
router.get('/received', TransactionController.getReceivedTransactions);
router.get('/sent', TransactionController.getSentTransactions);
router.get('/:transactionId', TransactionController.getTransaction);

module.exports = router;
