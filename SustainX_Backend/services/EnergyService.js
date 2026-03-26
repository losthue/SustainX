const { Op } = require('sequelize');
const User = require('../models/User');
const EnergyData = require('../models/EnergyData');

class EnergyService {
    static convertKWhToCoins(kWh, conversionRate = 10) {
        return Number(kWh) * Number(conversionRate);
    }

    static async recordEnergyData(userId, importedKWh, exportedKWh, conversionRate = 10) {
        const user = await User.findByPk(userId);
        if (!user) throw new Error('User not found');

        const netEnergy = Number(exportedKWh) - Number(importedKWh);
        let yellowCoins = 0;
        let greenCoins = 0;
        let redCoins = 0;

        if (netEnergy > 0) {
            yellowCoins = this.convertKWhToCoins(exportedKWh, conversionRate);
            greenCoins = this.convertKWhToCoins(netEnergy, conversionRate);
        } else {
            redCoins = this.convertKWhToCoins(Math.abs(netEnergy), conversionRate);
            yellowCoins = this.convertKWhToCoins(exportedKWh, conversionRate);
            greenCoins = Math.max(0, this.convertKWhToCoins(netEnergy, conversionRate));
        }

        const energyData = await EnergyData.create({
            userId,
            importedKWh,
            exportedKWh,
            measurementDate: new Date(),
            conversionRate,
            status: 'verified',
            dataSource: 'manual_entry',
            yellowCoinsEarned: yellowCoins,
            greenCoinsGenerated: greenCoins,
            redCoinsIncurred: redCoins,
        });

        user.yellowCoins = Number(user.yellowCoins) + Number(yellowCoins);
        user.greenCoins = Number(user.greenCoins) + Number(greenCoins);
        user.redCoins = Number(user.redCoins) + Number(redCoins);
        user.energyScore += Math.round(Number(exportedKWh) + Math.abs(netEnergy));
        await user.save();

        return {
            success: true,
            message: 'Energy data processed successfully',
            energyData,
            userWallet: user.getWalletInfo(),
        };
    }

    static async getEnergyHistory(userId, limit = 30) {
        return EnergyData.findAll({
            where: { userId },
            order: [['measurementDate', 'DESC']],
            limit,
        });
    }

    static async getEnergyStats(userId, days = 30) {
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - days);

        const records = await EnergyData.findAll({
            where: {
                userId,
                measurementDate: { [Op.gte]: startDate },
            },
        });

        const stats = records.reduce(
            (acc, r) => {
                acc.totalImported += Number(r.importedKWh);
                acc.totalExported += Number(r.exportedKWh);
                acc.totalYellowCoins += Number(r.yellowCoinsEarned);
                acc.totalGreenCoins += Number(r.greenCoinsGenerated);
                acc.totalRedCoins += Number(r.redCoinsIncurred);
                acc.totalNet += Number(r.netEnergy);
                acc.count += 1;
                return acc;
            },
            { totalImported: 0, totalExported: 0, totalYellowCoins: 0, totalGreenCoins: 0, totalRedCoins: 0, totalNet: 0, count: 0 }
        );

        return {
            totalImported: stats.totalImported,
            totalExported: stats.totalExported,
            totalYellowCoins: stats.totalYellowCoins,
            totalGreenCoins: stats.totalGreenCoins,
            totalRedCoins: stats.totalRedCoins,
            averageNetEnergy: stats.count ? stats.totalNet / stats.count : 0,
            dataPoints: stats.count,
        };
    }

    static async processMeterReadings(readings) {
        const MeterReading = require('../models/MeterReading');
        const createdRecords = [];

        for (const reading of readings) {
            const { user_id, user_type, meter_id, billing_cycle, imports_kwh, exports_kwh } = reading;
            const userId = user_id;

            let user = await User.findByPk(userId);
            if (!user) {
                user = await User.create({
                    id: userId,
                    username: `user_${userId.replace(/[^a-z0-9]/gi, '_').toLowerCase()}`,
                    email: `${userId}@energypass.local`,
                    password: 'TempPassword@123',
                });
            }

            const net_kwh = Number(exports_kwh) - Number(imports_kwh);
            await MeterReading.create({
                userId,
                userType: user_type,
                meterId: meter_id,
                billingCycle: billing_cycle,
                imports_kwh,
                exports_kwh,
                net_kwh,
            });

            const result = await this.recordEnergyData(userId, imports_kwh, exports_kwh);
            createdRecords.push({ reading, result });
        }

        return createdRecords;
    }

    static async updateConversionRate(newRate) {
        if (newRate <= 0) throw new Error('Conversion rate must be positive');
        return {
            success: true,
            message: 'Conversion rate updated',
            rate: newRate,
        };
    }
}

module.exports = EnergyService;
