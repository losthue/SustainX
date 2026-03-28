const { sequelize } = require('../config/db');
const { QueryTypes } = require('sequelize');
const User = require('../models/User');
const Wallet = require('../models/Wallet');

class WalletService {

    // ─────────────────────────────────────────────────────────────────────
    // Get wallet overview (uses vw_wallet_overview view)
    // ─────────────────────────────────────────────────────────────────────
    static async getWallet(userId) {
        const [rows] = await sequelize.query(
            'SELECT * FROM vw_wallet_overview WHERE user_id = ?',
            { replacements: [userId] }
        );

        if (!rows || rows.length === 0) {
            throw new Error('Wallet not found');
        }

        const row = rows[0];
        return {
            user_id: row.user_id,
            user_type: row.user_type,
            name: row.name,
            yellow_coins: parseFloat(row.yellow_coins),
            green_coins: parseFloat(row.green_coins),
            red_coins: parseFloat(row.red_coins),
            updated_at: row.updated_at,
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Get wallet balance (lighter call)
    // ─────────────────────────────────────────────────────────────────────
    static async getWalletBalance(userId) {
        const wallet = await Wallet.findOne({ where: { user_id: userId } });
        if (!wallet) throw new Error('Wallet not found');

        return {
            user_id: userId,
            yellow_coins: parseFloat(wallet.yellow_coins),
            green_coins: parseFloat(wallet.green_coins),
            red_coins: parseFloat(wallet.red_coins),
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Transfer green coins (calls stored procedure)
    // ─────────────────────────────────────────────────────────────────────
    static async transferGreenCoins(senderId, receiverId, amount, note = '') {
        // Validate users exist
        const sender = await User.findByPk(senderId);
        if (!sender) throw new Error('Sender not found');

        const receiver = await User.findByPk(receiverId);
        if (!receiver) throw new Error('Receiver not found');

        if (senderId === receiverId) {
            throw new Error('Cannot transfer to yourself');
        }

        const parsedAmount = parseFloat(amount);
        if (!parsedAmount || parsedAmount <= 0) {
            throw new Error('Amount must be greater than 0');
        }

        try {
            await sequelize.query(
                'CALL transfer_green_coins(:sender, :receiver, :amount, :note)',
                {
                    replacements: {
                        sender: senderId,
                        receiver: receiverId,
                        amount: parsedAmount,
                        note: note || `Transfer from ${senderId} to ${receiverId}`,
                    },
                    type: QueryTypes.RAW,
                }
            );
        } catch (err) {
            // MySQL stored procedure errors come through as SIGNAL
            if (err.original && err.original.sqlMessage) {
                throw new Error(err.original.sqlMessage);
            }
            throw err;
        }

        // Auto-offset: if receiver has red debt, burn received green to reduce it
        const receiverWallet = await Wallet.findOne({ where: { user_id: receiverId } });
        const recvGreen = parseFloat(receiverWallet.green_coins) || 0;
        const recvRed   = parseFloat(receiverWallet.red_coins) || 0;
        let offsetAmount = 0;

        if (recvGreen > 0 && recvRed > 0) {
            offsetAmount = Math.min(recvGreen, recvRed);
            await sequelize.query(
                `UPDATE wallets 
                 SET green_coins = green_coins - :offset,
                     red_coins   = red_coins   - :offset,
                     updated_at  = CURRENT_TIMESTAMP
                 WHERE user_id = :userId`,
                { replacements: { offset: offsetAmount, userId: receiverId } }
            );

            // Log the auto-offset transaction
            await sequelize.query(
                `INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, note, status)
                 VALUES (:userId, NULL, 'green', :offset, 'offset', 'Auto-offset after receiving green coins', 'completed')`,
                { replacements: { userId: receiverId, offset: offsetAmount } }
            );
        }

        // Return updated balances
        const senderWallet = await Wallet.findOne({ where: { user_id: senderId } });
        const updatedReceiverWallet = await Wallet.findOne({ where: { user_id: receiverId } });

        return {
            success: true,
            message: `Transferred ${parsedAmount} green coins from ${senderId} to ${receiverId}` +
                     (offsetAmount > 0 ? `. Auto-offset: ${offsetAmount.toFixed(1)} red coins cleared.` : ''),
            sender: {
                user_id: senderId,
                green_coins: parseFloat(senderWallet.green_coins),
            },
            receiver: {
                user_id: receiverId,
                green_coins: parseFloat(updatedReceiverWallet.green_coins),
                red_coins: parseFloat(updatedReceiverWallet.red_coins),
                offset_applied: offsetAmount,
            },
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Offset red coins with green (calls stored procedure)
    // ─────────────────────────────────────────────────────────────────────
    static async offsetRedWithGreen(userId, amount) {
        const parsedAmount = parseFloat(amount);
        if (!parsedAmount || parsedAmount <= 0) {
            throw new Error('Amount must be greater than 0');
        }

        try {
            await sequelize.query(
                'CALL offset_red_with_green(:userId, :amount)',
                {
                    replacements: { userId, amount: parsedAmount },
                    type: QueryTypes.RAW,
                }
            );
        } catch (err) {
            if (err.original && err.original.sqlMessage) {
                throw new Error(err.original.sqlMessage);
            }
            throw err;
        }

        const wallet = await Wallet.findOne({ where: { user_id: userId } });

        return {
            success: true,
            message: `Offset ${parsedAmount} red coins using green coins`,
            user_id: userId,
            green_coins: parseFloat(wallet.green_coins),
            red_coins: parseFloat(wallet.red_coins),
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Leaderboard (uses vw_top_contributors view)
    // ─────────────────────────────────────────────────────────────────────
    static async getLeaderboard(limit = 10) {
        const [rows] = await sequelize.query(
            'SELECT * FROM vw_top_contributors LIMIT ?',
            { replacements: [parseInt(limit)] }
        );

        return rows.map((row, index) => ({
            rank: index + 1,
            user_id: row.user_id,
            name: row.name,
            total_yellow: parseFloat(row.total_yellow),
            available_green: parseFloat(row.available_green),
            grid_debt: parseFloat(row.grid_debt),
        }));
    }

    // ─────────────────────────────────────────────────────────────────────
    // System-wide coin totals
    // ─────────────────────────────────────────────────────────────────────
    static async getSystemTotals() {
        const [rows] = await sequelize.query(
            `SELECT
                SUM(yellow_coins) AS total_yellow,
                SUM(green_coins)  AS total_green,
                SUM(red_coins)    AS total_red
            FROM wallets`
        );

        const row = rows[0];
        return {
            total_yellow: parseFloat(row.total_yellow) || 0,
            total_green: parseFloat(row.total_green) || 0,
            total_red: parseFloat(row.total_red) || 0,
        };
    }
}

module.exports = WalletService;