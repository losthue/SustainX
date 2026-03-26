const { Op } = require('sequelize');
const User = require('../models/User');
const Transaction = require('../models/Transaction');

class TransactionService {
    static async transferCoins(fromUserId, toUserId, yellowCoins = 0, greenCoins = 0, redCoins = 0, note = '') {
        if (fromUserId === toUserId) {
            throw new Error('Cannot transfer to yourself');
        }

        const sender = await User.findByPk(fromUserId);
        const receiver = await User.findByPk(toUserId);

        if (!sender || !receiver) {
            throw new Error('User not found');
        }

        const totalAmount = Number(yellowCoins) + Number(greenCoins) + Number(redCoins);
        if (totalAmount <= 0) {
            throw new Error('Transfer amount must be greater than 0');
        }

        if (sender.yellowCoins < yellowCoins) throw new Error('Insufficient yellow coins');
        if (sender.greenCoins < greenCoins) throw new Error('Insufficient green coins');
        if (sender.redCoins < redCoins) throw new Error('Insufficient red coins');

        const transaction = await Transaction.create({
            fromUserId,
            toUserId,
            yellowCoinsTransferred: yellowCoins,
            greenCoinsTransferred: greenCoins,
            redCoinsTransferred: redCoins,
            totalAmount,
            description: `Transfer of ${totalAmount} coins`,
            note,
            transactionType: 'transfer',
            status: 'completed',
            completedAt: new Date(),
        });

        sender.yellowCoins -= yellowCoins;
        sender.greenCoins -= greenCoins;
        sender.redCoins -= redCoins;
        receiver.yellowCoins += yellowCoins;
        receiver.greenCoins += greenCoins;
        receiver.redCoins += redCoins;

        sender.energyScore += 5;
        receiver.energyScore += 10;

        await sender.save();
        await receiver.save();

        return {
            success: true,
            message: 'Transfer completed successfully',
            transaction: {
                transactionId: transaction.id,
                from: sender.username,
                to: receiver.username,
                coinsTransferred: { yellow: yellowCoins, green: greenCoins, red: redCoins },
                totalAmount,
                timestamp: transaction.createdAt,
            },
            senderBalance: sender.getWalletInfo(),
            receiverBalance: receiver.getWalletInfo(),
        };
    }

    static async getTransactionHistory(userId, limit = 50) {
        return Transaction.findAll({
            where: { [Op.or]: [{ fromUserId: userId }, { toUserId: userId }] },
            order: [['createdAt', 'DESC']],
            limit,
        });
    }

    static async getTransactionById(transactionId) {
        const transaction = await Transaction.findByPk(transactionId);
        if (!transaction) throw new Error('Transaction not found');
        return transaction;
    }

    static async getTransactionStats(userId) {
        const transactions = await Transaction.findAll({
            where: { [Op.or]: [{ fromUserId: userId }, { toUserId: userId }], status: 'completed' },
        });

        const stats = transactions.reduce(
            (acc, tx) => {
                acc.totalTransactions += 1;
                acc.totalYellowTransferred += Number(tx.yellowCoinsTransferred);
                acc.totalGreenTransferred += Number(tx.greenCoinsTransferred);
                acc.totalRedTransferred += Number(tx.redCoinsTransferred);
                acc.totalAmount += Number(tx.totalAmount);
                return acc;
            },
            { totalTransactions: 0, totalYellowTransferred: 0, totalGreenTransferred: 0, totalRedTransferred: 0, totalAmount: 0 }
        );

        return {
            ...stats,
            averageAmount: stats.totalTransactions ? stats.totalAmount / stats.totalTransactions : 0,
        };
    }

    static async getReceivedTransactions(userId, limit = 30) {
        return Transaction.findAll({
            where: { toUserId: userId, status: 'completed' },
            order: [['createdAt', 'DESC']],
            limit,
        });
    }

    static async getSentTransactions(userId, limit = 30) {
        return Transaction.findAll({
            where: { fromUserId: userId, status: 'completed' },
            order: [['createdAt', 'DESC']],
            limit,
        });
    }
}

module.exports = TransactionService;
