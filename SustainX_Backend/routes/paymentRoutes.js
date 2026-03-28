const express = require('express');
const router = express.Router();
const PaymentController = require('../controllers/PaymentController');
const { authMiddleware } = require('../middleware/auth');

// All routes are protected
router.use(authMiddleware);

// Get available packages
router.get('/packages', PaymentController.getPackages);

// Create payment intent for mobile payment sheet
router.post('/create-payment-intent', PaymentController.createPaymentIntent);

// Confirm payment after successful payment sheet
router.post('/confirm', PaymentController.confirmPayment);

// Purchase history
router.get('/history', PaymentController.getPurchaseHistory);

module.exports = router;
