const { sequelize } = require('../config/db');
const { QueryTypes } = require('sequelize');
const EnergyReading = require('../models/EnergyReading');
const CoinGenerationLog = require('../models/CoinGenerationLog');
const WeatherService = require('./WeatherService');
const WalletService = require('./WalletService');

// Conversion rates (centralized)
// Green is NOT minted from energy readings — only yellow and red are minted.
const COIN_RATES = {
    yellow: 1.0,   // 1 kWh surplus  = 1 yellow coin (auto-offsets red debt)
    red:    1.5,   // 1 kWh deficit  = 1.5 red coins (grid consumption penalty)
};

class EnergyService {

    // ─────────────────────────────────────────────────────────────────────
    // Get conversion rates (AI-adjusted based on weather)
    // ─────────────────────────────────────────────────────────────────────
    static async getConversionRates() {
        try {
            const dynamicRates = await WeatherService.getCurrentRates();
            return {
                yellow: { rate: dynamicRates.yellow, description: `1 kWh surplus = ${dynamicRates.yellow} yellow coins (AI-adjusted)` },
                green:  { rate: null, description: 'Green coins are not minted from energy — obtained via marketplace or P2P sale' },
                red:    { rate: dynamicRates.red,    description: `1 kWh deficit = ${dynamicRates.red} red coins (penalty)` },
                offset: { rate: 1.0, description: '1 yellow coin offsets 1 red coin' },
                weather: dynamicRates.weather,
                ai_reasoning: dynamicRates.ai_reasoning,
            };
        } catch (err) {
            console.error('Failed to get AI rates:', err.message);
            return {
                yellow: { rate: COIN_RATES.yellow, description: `1 kWh surplus = ${COIN_RATES.yellow} yellow coin (fallback)` },
                green:  { rate: null, description: 'Green coins are not minted from energy — obtained via marketplace or P2P sale' },
                red:    { rate: COIN_RATES.red,    description: `1 kWh deficit = ${COIN_RATES.red} red coins (penalty)` },
                offset: { rate: 1.0, description: '1 yellow coin offsets 1 red coin' },
            };
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Record energy reading (manual user input)
    // ─────────────────────────────────────────────────────────────────────
    static async recordReading(userId, importKwh, exportKwh, billingCycle) {
        const impKwh = parseFloat(importKwh);
        const expKwh = parseFloat(exportKwh);
        let cycle = billingCycle ? parseInt(billingCycle) : null;

        // Validate inputs
        if (isNaN(impKwh) || impKwh < 0) throw new Error('import_kwh must be a non-negative number');
        if (isNaN(expKwh) || expKwh < 0) throw new Error('export_kwh must be a non-negative number');
        if (impKwh > 500)                throw new Error('import_kwh exceeds maximum allowed (500 kWh)');
        if (expKwh > 500)                throw new Error('export_kwh exceeds maximum allowed (500 kWh)');

        // Auto-detect next billing cycle if not provided
        if (!cycle || cycle <= 0) {
            const [maxResult] = await sequelize.query(
                'SELECT COALESCE(MAX(billing_cycle), 0) AS max_cycle FROM energy_readings WHERE user_id = ?',
                { replacements: [userId] }
            );
            cycle = (maxResult[0]?.max_cycle || 0) + 1;
        }

        // Check if user has a meter
        const [meters] = await sequelize.query(
            'SELECT meter_id FROM meters WHERE user_id = ? LIMIT 1',
            { replacements: [userId] }
        );

        let meterId;
        if (meters.length === 0) {
            // Auto-create a meter for the user
            const newMeterId = `M_${userId}`;
            await sequelize.query(
                'INSERT IGNORE INTO meters (meter_id, user_id) VALUES (?, ?)',
                { replacements: [newMeterId, userId] }
            );
            meterId = newMeterId;
        } else {
            meterId = meters[0].meter_id;
        }

        // Check for duplicate cycle entry
        const existing = await EnergyReading.findOne({
            where: { user_id: userId, billing_cycle: cycle },
        });

        if (existing) {
            // Update existing reading
            existing.import_kwh = impKwh;
            existing.export_kwh = expKwh;
            existing.meter_id = meterId;
            await existing.save();

            // Calculate net kWh (coins will be generated later via generateCoinsForCycle)
            const netKwh = expKwh - impKwh;

            return {
                action: 'updated',
                reading: {
                    reading_id: existing.reading_id,
                    user_id: userId,
                    meter_id: meterId,
                    import_kwh: impKwh,
                    export_kwh: expKwh,
                    net_kwh: netKwh,
                    billing_cycle: cycle,
                    coins_generated: { yellow: 0, green: 0, red: 0 }, // No immediate generation
                },
            };
        }

        // Create new reading
        const reading = await EnergyReading.create({
            user_id: userId,
            meter_id: meterId,
            import_kwh: impKwh,
            export_kwh: expKwh,
            billing_cycle: cycle,
        });

        // Calculate net kWh (coins will be generated later via generateCoinsForCycle)
        const netKwh = expKwh - impKwh;

        return {
            action: 'created',
            reading: {
                reading_id: reading.reading_id,
                user_id: userId,
                meter_id: meterId,
                import_kwh: impKwh,
                export_kwh: expKwh,
                net_kwh: netKwh,
                billing_cycle: cycle,
                coins_generated: { yellow: 0, green: 0, red: 0 }, // No immediate generation
            },
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Get energy totals for a user
    // ─────────────────────────────────────────────────────────────────────
    static async getEnergyTotals(userId) {
        const readings = await EnergyReading.findAll({
            where: { user_id: userId },
        });

        let totalImport = 0;
        let totalExport = 0;

        for (const r of readings) {
            totalImport += parseFloat(r.import_kwh) || 0;
            totalExport += parseFloat(r.export_kwh) || 0;
        }

        return {
            total_import_kwh: totalImport,
            total_export_kwh: totalExport,
            net_kwh: totalExport - totalImport,
            cycle_count: readings.length,
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Get per-cycle breakdown (uses vw_cycle_coin_summary view)
    // ─────────────────────────────────────────────────────────────────────
    static async getCycleBreakdown(userId) {
        const [rows] = await sequelize.query(
            'SELECT * FROM vw_cycle_coin_summary WHERE user_id = ? ORDER BY billing_cycle ASC',
            { replacements: [userId] }
        );

        return rows.map((r) => ({
            billing_cycle: r.billing_cycle,
            user_type: r.user_type,
            import_kwh: parseFloat(r.import_kwh),
            export_kwh: parseFloat(r.export_kwh),
            net_kwh: parseFloat(r.net_kwh),
            yellow_coins_minted: parseFloat(r.yellow_coins_minted),
            green_coins_minted: parseFloat(r.green_coins_minted),
            red_coins_minted: parseFloat(r.red_coins_minted),
        }));
    }

    // ─────────────────────────────────────────────────────────────────────
    // Get energy readings for a user (raw data)
    // ─────────────────────────────────────────────────────────────────────
    static async getReadings(userId) {
        const readings = await EnergyReading.findAll({
            where: { user_id: userId },
            order: [['billing_cycle', 'ASC']],
        });

        return readings.map((r) => ({
            reading_id: r.reading_id,
            user_id: r.user_id,
            meter_id: r.meter_id,
            import_kwh: parseFloat(r.import_kwh),
            export_kwh: parseFloat(r.export_kwh),
            net_kwh: parseFloat(r.net_kwh),
            billing_cycle: r.billing_cycle,
            recorded_at: r.recorded_at,
        }));
    }

    // ─────────────────────────────────────────────────────────────────────
    // Generate coins for a billing cycle (calls stored procedure)
    // ─────────────────────────────────────────────────────────────────────
    static async generateCoinsForCycle(billingCycle) {
        const cycle = parseInt(billingCycle);
        if (!cycle || cycle <= 0) {
            throw new Error('Billing cycle must be a positive integer');
        }

        // Get AI-adjusted rates
        let yellowRate = COIN_RATES.yellow;
        let greenRate = 0.5; // Default green rate
        let redRate = COIN_RATES.red;

        try {
            const dynamicRates = await WeatherService.getCurrentRates();
            yellowRate = dynamicRates.yellow;
            greenRate = dynamicRates.green;
            redRate = dynamicRates.red;
            console.log(`Using AI rates for cycle ${cycle}: Y=${yellowRate} G=${greenRate} R=${redRate} (${dynamicRates.ai_reasoning})`);
        } catch (err) {
            console.warn('Using default rates:', err.message);
        }

        try {
            await sequelize.query(
                'CALL generate_coins_for_cycle(:cycle, :yr, :gr, :rr)',
                {
                    replacements: { cycle, yr: yellowRate, gr: greenRate, rr: redRate },
                    type: QueryTypes.RAW,
                }
            );
        } catch (err) {
            if (err.original && err.original.sqlMessage) {
                throw new Error(err.original.sqlMessage);
            }
            throw err;
        }

        // Return what was generated
        const logs = await CoinGenerationLog.findAll({
            where: { billing_cycle: cycle },
        });

        // Auto-offset: for every wallet with both yellow and red balance,
        // clear the red using yellow if present.
        const [offsetWallets] = await sequelize.query(
            'SELECT user_id FROM wallets WHERE yellow_coins > 0 AND red_coins > 0'
        );

        const offsetResults = {};
        for (const w of offsetWallets) {
            const offsetted = await WalletService.autoOffset(w.user_id);
            if (offsetted > 0) {
                offsetResults[w.user_id] = offsetted;
            }
        }

        return {
            billing_cycle: cycle,
            users_processed: logs.length,
            summary: logs.map((l) => ({
                user_id: l.user_id,
                import_kwh: parseFloat(l.import_kwh),
                export_kwh: parseFloat(l.export_kwh),
                net_kwh: parseFloat(l.net_kwh),
                yellow_coins_minted: parseFloat(l.yellow_coins_minted),
                green_coins_minted: parseFloat(l.green_coins_minted),
                red_coins_minted: parseFloat(l.red_coins_minted),
                red_coins_offset: offsetResults[l.user_id] || 0,
            })),
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Get coin generation history for a user
    // ─────────────────────────────────────────────────────────────────────
    static async getCoinGenerationHistory(userId) {
        const logs = await CoinGenerationLog.findAll({
            where: { user_id: userId },
            order: [['billing_cycle', 'ASC']],
        });

        return logs.map((l) => ({
            billing_cycle: l.billing_cycle,
            import_kwh: parseFloat(l.import_kwh),
            export_kwh: parseFloat(l.export_kwh),
            net_kwh: parseFloat(l.net_kwh),
            yellow_coins_minted: parseFloat(l.yellow_coins_minted),
            green_coins_minted: parseFloat(l.green_coins_minted),
            red_coins_minted: parseFloat(l.red_coins_minted),
            generated_at: l.generated_at,
        }));
    }

    // ─────────────────────────────────────────────────────────────────────
    // Get cycle summary for all users (for charts)
    // ─────────────────────────────────────────────────────────────────────
    static async getCycleSummary(billingCycle) {
        const [rows] = await sequelize.query(
            'SELECT * FROM vw_cycle_coin_summary WHERE billing_cycle = ?',
            { replacements: [parseInt(billingCycle)] }
        );

        return rows.map((r) => ({
            user_id: r.user_id,
            user_type: r.user_type,
            import_kwh: parseFloat(r.import_kwh),
            export_kwh: parseFloat(r.export_kwh),
            net_kwh: parseFloat(r.net_kwh),
            yellow_coins_minted: parseFloat(r.yellow_coins_minted),
            green_coins_minted: parseFloat(r.green_coins_minted),
            red_coins_minted: parseFloat(r.red_coins_minted),
        }));
    }
}

module.exports = EnergyService;