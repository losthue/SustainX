const TransactionService = require('../services/TransactionService');

class TransactionController {

    // GET /transactions/history
    static async getTransactionHistory(req, res, next) {
        try {
            const { limit = 50 } = req.query;
            const transactions = await TransactionService.getTransactionHistory(req.userId, parseInt(limit));
            return res.status(200).json({
                success: true,
                data: transactions,
                count: transactions.length,
            });
        } catch (err) { next(err); }
    }

    // GET /transactions/:transactionId
    static async getTransaction(req, res, next) {
        try {
            const { transactionId } = req.params;
            const transaction = await TransactionService.getTransactionById(transactionId);
            return res.status(200).json({ success: true, data: transaction });
        } catch (err) { next(err); }
    }

    // GET /transactions/stats
    static async getTransactionStats(req, res, next) {
        try {
            const stats = await TransactionService.getTransactionStats(req.userId);
            return res.status(200).json({ success: true, data: stats });
        } catch (err) { next(err); }
    }

    // GET /transactions/received
    static async getReceivedTransactions(req, res, next) {
        try {
            const { limit = 30 } = req.query;
            const transactions = await TransactionService.getReceivedTransactions(req.userId, parseInt(limit));
            return res.status(200).json({
                success: true,
                data: transactions,
                type: 'received',
                count: transactions.length,
            });
        } catch (err) { next(err); }
    }

    // GET /transactions/sent
    static async getSentTransactions(req, res, next) {
        try {
            const { limit = 30 } = req.query;
            const transactions = await TransactionService.getSentTransactions(req.userId, parseInt(limit));
            return res.status(200).json({
                success: true,
                data: transactions,
                type: 'sent',
                count: transactions.length,
            });
        } catch (err) { next(err); }
    }
}

module.exports = TransactionController;
