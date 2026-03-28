const express = require('express');
const router = express.Router();
const EnergyController = require('../controllers/EnergyController');
const { authMiddleware } = require('../middleware/auth');

// All energy routes require authentication
router.use(authMiddleware);

// Energy data endpoints
router.get('/totals', EnergyController.getEnergyTotals);
router.get('/readings', EnergyController.getReadings);
router.get('/cycles', EnergyController.getCycleBreakdown);
router.get('/coin-history', EnergyController.getCoinGenerationHistory);
router.get('/rates', EnergyController.getConversionRates);

// Manual energy recording
router.post('/record', EnergyController.recordReading);

// Coin generation (triggers stored procedure)
router.post('/generate-coins', EnergyController.generateCoins);

// Cycle summary for all users (charts)
router.get('/cycle-summary/:cycle', EnergyController.getCycleSummary);

module.exports = router;
