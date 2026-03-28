const { DataTypes, Model } = require('sequelize');
const { sequelize } = require('../config/db');

class Wallet extends Model {}

Wallet.init(
    {
        wallet_id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        user_id: {
            type: DataTypes.STRING(10),
            allowNull: false,
            unique: true,
        },
        yellow_coins: {
            type: DataTypes.DECIMAL(10, 4),
            allowNull: false,
            defaultValue: 0,
        },
        green_coins: {
            type: DataTypes.DECIMAL(10, 4),
            allowNull: false,
            defaultValue: 0,
        },
        red_coins: {
            type: DataTypes.DECIMAL(10, 4),
            allowNull: false,
            defaultValue: 0,
        },
    },
    {
        sequelize,
        modelName: 'Wallet',
        tableName: 'wallets',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at',
    }
);

module.exports = Wallet;
