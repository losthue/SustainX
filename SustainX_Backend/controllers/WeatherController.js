const WeatherService = require('../services/WeatherService');

class WeatherController {

    // GET /weather/forecast
    static async getWeatherAndRates(req, res, next) {
        try {
            const { lat, lon } = req.query;
            const data = await WeatherService.getWeatherAndRates(
                lat ? parseFloat(lat) : undefined,
                lon ? parseFloat(lon) : undefined
            );
            return res.status(200).json({ success: true, data });
        } catch (err) {
            console.error('Weather API error:', err.message);
            return res.status(502).json({
                success: false,
                message: 'Unable to fetch weather data: ' + err.message,
            });
        }
    }
}

module.exports = WeatherController;
