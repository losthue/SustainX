const { DataTypes, Model } = require('sequelize');
const { sequelize } = require('../config/db');

class EnergyData extends Model {}

EnergyData.init(
    {
        userId: {
            type: DataTypes.STRING(64),
            allowNull: false,
        },
        importedKWh: {
            type: DataTypes.DECIMAL(10,2),
            allowNull: false,
            defaultValue: 0,
            validate: { min: 0 },
        },
        exportedKWh: {
            type: DataTypes.DECIMAL(10,2),
            allowNull: false,
            defaultValue: 0,
            validate: { min: 0 },
        },
        netEnergy: {
            type: DataTypes.DECIMAL(10,2),
        },
        yellowCoinsEarned: {
            type: DataTypes.DECIMAL(16,2),
            defaultValue: 0,
        },
        greenCoinsGenerated: {
            type: DataTypes.DECIMAL(16,2),
            defaultValue: 0,
        },
        redCoinsIncurred: {
            type: DataTypes.DECIMAL(16,2),
            defaultValue: 0,
        },
        conversionRate: {
            type: DataTypes.DECIMAL(10,2),
            defaultValue: 10,
        },
        measurementDate: {
            type: DataTypes.DATE,
            allowNull: false,
        },
        startTime: DataTypes.DATE,
        endTime: DataTypes.DATE,
        durationHours: DataTypes.DECIMAL(10,2),
        dataSource: {
            type: DataTypes.ENUM('smart_meter', 'manual_entry', 'api_integration', 'historical'),
            defaultValue: 'smart_meter',
        },
        status: {
            type: DataTypes.ENUM('pending', 'verified', 'processed', 'archived'),
            defaultValue: 'pending',
        },
        deviceId: DataTypes.STRING,
        notes: DataTypes.STRING,
    },
    {
        sequelize,
        modelName: 'EnergyData',
        tableName: 'energy_data',
        timestamps: true,
        hooks: {
            beforeCreate: (energyData) => {
                energyData.netEnergy = Number(energyData.exportedKWh) - Number(energyData.importedKWh);
            },
            beforeUpdate: (energyData) => {
                energyData.netEnergy = Number(energyData.exportedKWh) - Number(energyData.importedKWh);
            },
        },
    }
);

module.exports = EnergyData;
