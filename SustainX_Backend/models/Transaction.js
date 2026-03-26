const { DataTypes, Model } = require('sequelize');
const { sequelize } = require('../config/db');

class Transaction extends Model {}

Transaction.init(
    {
        fromUserId: {
            type: DataTypes.STRING(64),
            allowNull: false,
        },
        toUserId: {
            type: DataTypes.STRING(64),
            allowNull: false,
        },
        yellowCoinsTransferred: {
            type: DataTypes.DECIMAL(16, 2),
            defaultValue: 0,
        },
        greenCoinsTransferred: {
            type: DataTypes.DECIMAL(16, 2),
            defaultValue: 0,
        },
        redCoinsTransferred: {
            type: DataTypes.DECIMAL(16, 2),
            defaultValue: 0,
        },
        totalAmount: {
            type: DataTypes.DECIMAL(16, 2),
            allowNull: false,
        },
        description: DataTypes.STRING,
        note: DataTypes.STRING,
        transactionType: {
            type: DataTypes.ENUM('transfer', 'conversion', 'reward', 'purchase', 'redeem'),
            defaultValue: 'transfer',
        },
        status: {
            type: DataTypes.ENUM('pending', 'completed', 'failed', 'cancelled'),
            defaultValue: 'pending',
        },
        completedAt: DataTypes.DATE,
    },
    {
        sequelize,
        modelName: 'Transaction',
        tableName: 'transactions',
        timestamps: true,
        createdAt: true,
        updatedAt: false,
    }
);

module.exports = Transaction;
