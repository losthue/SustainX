const { DataTypes, Model } = require('sequelize');
const { sequelize } = require('../config/db');

class Transaction extends Model {}

Transaction.init(
    {
        transaction_id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        sender_id: {
            type: DataTypes.STRING(10),
            allowNull: true, // NULL for system mint/burn
        },
        receiver_id: {
            type: DataTypes.STRING(10),
            allowNull: true, // NULL for burns
        },
        coin_type: {
            type: DataTypes.ENUM('green', 'red'),
            allowNull: false,
        },
        amount: {
            type: DataTypes.DECIMAL(10, 4),
            allowNull: false,
        },
        transaction_type: {
            type: DataTypes.ENUM('mint', 'transfer', 'offset', 'burn'),
            allowNull: false,
        },
        billing_cycle: {
            type: DataTypes.INTEGER,
            allowNull: true,
        },
        note: {
            type: DataTypes.STRING(255),
            allowNull: true,
        },
        status: {
            type: DataTypes.ENUM('pending', 'completed', 'failed'),
            defaultValue: 'pending',
        },
        created_at: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW,
        },
    },
    {
        sequelize,
        modelName: 'Transaction',
        tableName: 'transactions',
        timestamps: false,
    }
);

module.exports = Transaction;
