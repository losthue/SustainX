const TransactionService = require('../services/TransactionService');

class TransactionController {
    // Transfer coins
    static async transferCoins(req, res, next) {
        try {
            const fromUserId = req.userId;
            const { toUserId, yellowCoins = 0, greenCoins = 0, redCoins = 0, note = '' } = req.body;

            // Validate input
            if (!toUserId) {
                return res.status(400).json({
                    success: false,
                    message: 'Recipient user ID is required'
                });
            }

            if (yellowCoins < 0 || greenCoins < 0 || redCoins < 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Coin amounts cannot be negative'
                });
            }

            // Perform transfer
            const result = await TransactionService.transferCoins(
                fromUserId,
                toUserId,
                yellowCoins,
                greenCoins,
                redCoins,
                note
            );

            return res.status(201).json(result);
        } catch (err) {
            if (err.message.includes('Insufficient')) {
                return res.status(400).json({
                    success: false,
                    message: err.message
                });
            }
            next(err);
        }
    }

    // Get transaction history
    static async getTransactionHistory(req, res, next) {
        try {
            const userId = req.userId;
            const { limit = 50 } = req.query;

            const transactions = await TransactionService.getTransactionHistory(userId, parseInt(limit));

            return res.status(200).json({
                success: true,
                data: transactions,
                count: transactions.length
            });
        } catch (err) {
            next(err);
        }
    }

    // Get transaction by ID
    static async getTransaction(req, res, next) {
        try {
            const { transactionId } = req.params;

            const transaction = await TransactionService.getTransactionById(transactionId);

            return res.status(200).json({
                success: true,
                data: transaction
            });
        } catch (err) {
            next(err);
        }
    }

    // Get transaction statistics
    static async getTransactionStats(req, res, next) {
        try {
            const userId = req.userId;

            const stats = await TransactionService.getTransactionStats(userId);

            return res.status(200).json({
                success: true,
                data: stats
            });
        } catch (err) {
            next(err);
        }
    }

    // Get received transactions
    static async getReceivedTransactions(req, res, next) {
        try {
            const userId = req.userId;
            const { limit = 30 } = req.query;

            const transactions = await TransactionService.getReceivedTransactions(userId, parseInt(limit));

            return res.status(200).json({
                success: true,
                data: transactions,
                type: 'received',
                count: transactions.length
            });
        } catch (err) {
            next(err);
        }
    }

    // Get sent transactions
    static async getSentTransactions(req, res, next) {
        try {
            const userId = req.userId;
            const { limit = 30 } = req.query;

            const transactions = await TransactionService.getSentTransactions(userId, parseInt(limit));

            return res.status(200).json({
                success: true,
                data: transactions,
                type: 'sent',
                count: transactions.length
            });
        } catch (err) {
            next(err);
        }
    }
}

module.exports = TransactionController;
