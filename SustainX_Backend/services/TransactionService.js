const { sequelize } = require('../config/db');
const { QueryTypes } = require('sequelize');
const Transaction = require('../models/Transaction');

class TransactionService {

    // ─────────────────────────────────────────────────────────────────────
    // Get transaction history for a user (uses vw_transaction_history view)
    // ─────────────────────────────────────────────────────────────────────
    static async getTransactionHistory(userId, limit = 50) {
        const [rows] = await sequelize.query(
            `SELECT * FROM vw_transaction_history
             WHERE sender_id = ? OR receiver_id = ?
             ORDER BY created_at DESC
             LIMIT ?`,
            { replacements: [userId, userId, parseInt(limit)] }
        );

        return rows.map((r) => ({
            transaction_id: r.transaction_id,
            transaction_type: r.transaction_type,
            coin_type: r.coin_type,
            amount: parseFloat(r.amount),
            sender_id: r.sender_id,
            sender_name: r.sender_name,
            receiver_id: r.receiver_id,
            receiver_name: r.receiver_name,
            billing_cycle: r.billing_cycle,
            note: r.note,
            status: r.status,
            created_at: r.created_at,
        }));
    }

    // ─────────────────────────────────────────────────────────────────────
    // Get transaction by ID
    // ─────────────────────────────────────────────────────────────────────
    static async getTransactionById(transactionId) {
        const transaction = await Transaction.findByPk(transactionId);
        if (!transaction) throw new Error('Transaction not found');

        return {
            transaction_id: transaction.transaction_id,
            sender_id: transaction.sender_id,
            receiver_id: transaction.receiver_id,
            coin_type: transaction.coin_type,
            amount: parseFloat(transaction.amount),
            transaction_type: transaction.transaction_type,
            billing_cycle: transaction.billing_cycle,
            note: transaction.note,
            status: transaction.status,
            created_at: transaction.created_at,
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Get transaction stats for a user
    // ─────────────────────────────────────────────────────────────────────
    static async getTransactionStats(userId) {
        const [rows] = await sequelize.query(
            `SELECT
                COUNT(*) AS total_transactions,
                SUM(CASE WHEN coin_type = 'green' THEN amount ELSE 0 END) AS total_green_amount,
                SUM(CASE WHEN coin_type = 'red' THEN amount ELSE 0 END) AS total_red_amount,
                SUM(CASE WHEN transaction_type = 'transfer' AND sender_id = ? THEN amount ELSE 0 END) AS total_sent,
                SUM(CASE WHEN transaction_type = 'transfer' AND receiver_id = ? THEN amount ELSE 0 END) AS total_received,
                SUM(CASE WHEN transaction_type = 'mint' AND receiver_id = ? THEN amount ELSE 0 END) AS total_minted,
                SUM(CASE WHEN transaction_type = 'offset' AND sender_id = ? THEN amount ELSE 0 END) AS total_offset
            FROM transactions
            WHERE (sender_id = ? OR receiver_id = ?) AND status = 'completed'`,
            { replacements: [userId, userId, userId, userId, userId, userId] }
        );

        const stats = rows[0];
        return {
            total_transactions: parseInt(stats.total_transactions) || 0,
            total_green_amount: parseFloat(stats.total_green_amount) || 0,
            total_red_amount: parseFloat(stats.total_red_amount) || 0,
            total_sent: parseFloat(stats.total_sent) || 0,
            total_received: parseFloat(stats.total_received) || 0,
            total_minted: parseFloat(stats.total_minted) || 0,
            total_offset: parseFloat(stats.total_offset) || 0,
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Get received transactions
    // ─────────────────────────────────────────────────────────────────────
    static async getReceivedTransactions(userId, limit = 30) {
        const [rows] = await sequelize.query(
            `SELECT * FROM vw_transaction_history
             WHERE receiver_id = ? AND transaction_type = 'transfer'
             ORDER BY created_at DESC
             LIMIT ?`,
            { replacements: [userId, parseInt(limit)] }
        );

        return rows;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Get sent transactions
    // ─────────────────────────────────────────────────────────────────────
    static async getSentTransactions(userId, limit = 30) {
        const [rows] = await sequelize.query(
            `SELECT * FROM vw_transaction_history
             WHERE sender_id = ? AND transaction_type = 'transfer'
             ORDER BY created_at DESC
             LIMIT ?`,
            { replacements: [userId, parseInt(limit)] }
        );

        return rows;
    }
}

module.exports = TransactionService;
