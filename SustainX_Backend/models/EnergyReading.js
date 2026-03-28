const { DataTypes, Model } = require('sequelize');
const { sequelize } = require('../config/db');

class EnergyReading extends Model {}

EnergyReading.init(
    {
        reading_id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        user_id: {
            type: DataTypes.STRING(10),
            allowNull: false,
        },
        meter_id: {
            type: DataTypes.STRING(10),
            allowNull: false,
        },
        import_kwh: {
            type: DataTypes.DECIMAL(10, 3),
            allowNull: false,
            defaultValue: 0,
        },
        export_kwh: {
            type: DataTypes.DECIMAL(10, 3),
            allowNull: false,
            defaultValue: 0,
        },
        billing_cycle: {
            type: DataTypes.INTEGER,
            allowNull: false,
        },
        net_kwh: {
            type: DataTypes.DECIMAL(10, 3),
            // Generated column in MySQL — read-only
        },
        recorded_at: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW,
        },
    },
    {
        sequelize,
        modelName: 'EnergyReading',
        tableName: 'energy_readings',
        timestamps: false,
    }
);

module.exports = EnergyReading;
