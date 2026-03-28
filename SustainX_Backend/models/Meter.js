const { DataTypes, Model } = require('sequelize');
const { sequelize } = require('../config/db');

class Meter extends Model {}

Meter.init(
    {
        meter_id: {
            type: DataTypes.STRING(10),
            primaryKey: true,
            allowNull: false,
        },
        user_id: {
            type: DataTypes.STRING(10),
            allowNull: false,
            unique: true,
        },
        installed_at: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW,
        },
    },
    {
        sequelize,
        modelName: 'Meter',
        tableName: 'meters',
        timestamps: false,
    }
);

module.exports = Meter;
