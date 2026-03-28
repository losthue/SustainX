const express = require('express');
const router = express.Router();
const WeatherController = require('../controllers/WeatherController');
const { authMiddleware } = require('../middleware/auth');

// Weather requires authentication
router.use(authMiddleware);

// GET /weather/forecast?lat=&lon=
router.get('/forecast', WeatherController.getWeatherAndRates);

module.exports = router;
