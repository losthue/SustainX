const { DataTypes, Model } = require('sequelize');
const { sequelize } = require('../config/db');

class CoinGenerationLog extends Model {}

CoinGenerationLog.init(
    {
        log_id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        user_id: {
            type: DataTypes.STRING(10),
            allowNull: false,
        },
        billing_cycle: {
            type: DataTypes.INTEGER,
            allowNull: false,
        },
        import_kwh: {
            type: DataTypes.DECIMAL(10, 3),
            allowNull: false,
        },
        export_kwh: {
            type: DataTypes.DECIMAL(10, 3),
            allowNull: false,
        },
        net_kwh: {
            type: DataTypes.DECIMAL(10, 3),
            allowNull: false,
        },
        yellow_coins_minted: {
            type: DataTypes.DECIMAL(10, 4),
            allowNull: false,
            defaultValue: 0,
        },
        green_coins_minted: {
            type: DataTypes.DECIMAL(10, 4),
            allowNull: false,
            defaultValue: 0,
        },
        red_coins_minted: {
            type: DataTypes.DECIMAL(10, 4),
            allowNull: false,
            defaultValue: 0,
        },
        generated_at: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW,
        },
    },
    {
        sequelize,
        modelName: 'CoinGenerationLog',
        tableName: 'coin_generation_log',
        timestamps: false,
    }
);

module.exports = CoinGenerationLog;
