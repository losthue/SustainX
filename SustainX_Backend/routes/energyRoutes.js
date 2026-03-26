const express = require('express');
const router = express.Router();
const EnergyController = require('../controllers/EnergyController');
const { authMiddleware } = require('../middleware/auth');

// All energy routes require authentication
router.use(authMiddleware);

// Energy data endpoints
router.post('/record', EnergyController.recordEnergyData);
router.get('/history', EnergyController.getEnergyHistory);
router.get('/stats', EnergyController.getEnergyStats);
router.post('/meter-readings', EnergyController.processMeterReadings);

// Admin endpoint (optional - for updating conversion rate)
router.put('/conversion-rate', EnergyController.updateConversionRate);

module.exports = router;
