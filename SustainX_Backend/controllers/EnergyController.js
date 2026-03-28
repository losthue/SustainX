const EnergyService = require('../services/EnergyService');

class EnergyController {

    // GET /energy/totals
    static async getEnergyTotals(req, res, next) {
        try {
            const totals = await EnergyService.getEnergyTotals(req.userId);
            return res.status(200).json({ success: true, data: totals });
        } catch (err) { next(err); }
    }

    // GET /energy/readings
    static async getReadings(req, res, next) {
        try {
            const readings = await EnergyService.getReadings(req.userId);
            return res.status(200).json({
                success: true,
                data: readings,
                count: readings.length,
            });
        } catch (err) { next(err); }
    }

    // GET /energy/cycles
    static async getCycleBreakdown(req, res, next) {
        try {
            const cycles = await EnergyService.getCycleBreakdown(req.userId);
            return res.status(200).json({ success: true, data: cycles });
        } catch (err) { next(err); }
    }

    // POST /energy/generate-coins
    // Body: { billing_cycle: number }
    static async generateCoins(req, res, next) {
        try {
            const { billing_cycle } = req.body;

            if (!billing_cycle || parseInt(billing_cycle) <= 0) {
                return res.status(400).json({
                    success: false,
                    message: 'billing_cycle must be a positive integer',
                });
            }

            const result = await EnergyService.generateCoinsForCycle(parseInt(billing_cycle));
            return res.status(200).json({ success: true, data: result });
        } catch (err) { next(err); }
    }

    // GET /energy/coin-history
    static async getCoinGenerationHistory(req, res, next) {
        try {
            const history = await EnergyService.getCoinGenerationHistory(req.userId);
            return res.status(200).json({
                success: true,
                data: history,
                count: history.length,
            });
        } catch (err) { next(err); }
    }

    // GET /energy/cycle-summary/:cycle
    static async getCycleSummary(req, res, next) {
        try {
            const { cycle } = req.params;
            const summary = await EnergyService.getCycleSummary(parseInt(cycle));
            return res.status(200).json({ success: true, data: summary });
        } catch (err) { next(err); }
    }

    // POST /energy/record
    // Body: { import_kwh, export_kwh, billing_cycle }
    static async recordReading(req, res, next) {
        try {
            const { import_kwh, export_kwh, billing_cycle } = req.body;

            if (import_kwh === undefined || export_kwh === undefined || !billing_cycle) {
                return res.status(400).json({
                    success: false,
                    message: 'import_kwh, export_kwh, and billing_cycle are required',
                });
            }

            const result = await EnergyService.recordReading(
                req.userId,
                import_kwh,
                export_kwh,
                billing_cycle
            );

            return res.status(result.action === 'created' ? 201 : 200).json({
                success: true,
                message: `Energy reading ${result.action} for cycle ${billing_cycle}`,
                data: result,
            });
        } catch (err) {
            if (err.message && (err.message.includes('must be') || err.message.includes('exceeds'))) {
                return res.status(400).json({ success: false, message: err.message });
            }
            next(err);
        }
    }

    // GET /energy/rates
    static async getConversionRates(req, res, next) {
        try {
            const rates = await EnergyService.getConversionRates();
            return res.status(200).json({ success: true, data: rates });
        } catch (err) { next(err); }
    }
}

module.exports = EnergyController;
