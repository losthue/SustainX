const EnergyService = require('../services/EnergyService');

class EnergyController {
    // Record energy data
    static async recordEnergyData(req, res, next) {
        try {
            const userId = req.userId;
            const { importedKWh, exportedKWh, conversionRate = 10 } = req.body;

            // Validate input
            if (importedKWh === undefined || exportedKWh === undefined) {
                return res.status(400).json({
                    success: false,
                    message: 'importedKWh and exportedKWh are required'
                });
            }

            if (importedKWh < 0 || exportedKWh < 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Energy values cannot be negative'
                });
            }

            // Record energy data
            const result = await EnergyService.recordEnergyData(userId, importedKWh, exportedKWh, conversionRate);

            return res.status(201).json(result);
        } catch (err) {
            next(err);
        }
    }

    // Get energy history
    static async getEnergyHistory(req, res, next) {
        try {
            const userId = req.userId;
            const { limit = 30 } = req.query;

            const history = await EnergyService.getEnergyHistory(userId, parseInt(limit));

            return res.status(200).json({
                success: true,
                data: history
            });
        } catch (err) {
            next(err);
        }
    }

    // Get energy statistics
    static async getEnergyStats(req, res, next) {
        try {
            const userId = req.userId;
            const { days = 30 } = req.query;

            const stats = await EnergyService.getEnergyStats(userId, parseInt(days));

            return res.status(200).json({
                success: true,
                data: stats,
                period: `${days} days`
            });
        } catch (err) {
            next(err);
        }
    }

    // Process meter readings batch
    static async processMeterReadings(req, res, next) {
        try {
            const { readings } = req.body;

            if (!Array.isArray(readings) || readings.length === 0) {
                return res.status(400).json({
                    success: false,
                    message: 'readings must be a non-empty array'
                });
            }

            const result = await EnergyService.processMeterReadings(readings);
            return res.status(201).json({
                success: true,
                message: 'Meter readings processed',
                processed: result.length,
                details: result,
            });
        } catch (err) {
            next(err);
        }
    }

    // Update conversion rate (admin function)
    static async updateConversionRate(req, res, next) {
        try {
            const { newRate } = req.body;

            if (!newRate || newRate <= 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Conversion rate must be a positive number'
                });
            }

            const result = await EnergyService.updateConversionRate(newRate);

            return res.status(200).json(result);
        } catch (err) {
            next(err);
        }
    }
}

module.exports = EnergyController;
