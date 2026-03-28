const { sequelize } = require('../config/db');
const { QueryTypes } = require('sequelize');
const User = require('../models/User');
const Wallet = require('../models/Wallet');

// Monetary values per coin (Rs)
const COIN_VALUES = {
    yellow: 4,
    green:  7,
    red:    10,
};
const PLATFORM_FEE = 0.20; // 20% platform commission on yellow→green sales

class WalletService {

    // ─────────────────────────────────────────────────────────────────────
    // Coin monetary values — reads from coin_values table (source of truth).
    // Falls back to JS constants if table is unavailable.
    // ─────────────────────────────────────────────────────────────────────
    static async getCoinValues() {
        try {
            const [rows] = await sequelize.query('SELECT coin_type, value_rs FROM coin_values');
            const map = {};
            for (const r of rows) map[r.coin_type] = parseFloat(r.value_rs);
            return {
                yellow_rs:       map.yellow ?? COIN_VALUES.yellow,
                green_rs:        map.green  ?? COIN_VALUES.green,
                red_rs:          map.red    ?? COIN_VALUES.red,
                platform_fee_pct: PLATFORM_FEE * 100,
                currency: 'MUR',
            };
        } catch {
            return {
                yellow_rs:       COIN_VALUES.yellow,
                green_rs:        COIN_VALUES.green,
                red_rs:          COIN_VALUES.red,
                platform_fee_pct: PLATFORM_FEE * 100,
                currency: 'MUR',
            };
        }
    }

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

        // Return updated balances
        const senderWallet = await Wallet.findOne({ where: { user_id: senderId } });
        const receiverWallet = await Wallet.findOne({ where: { user_id: receiverId } });

        // Auto-offset receiver's red coins with green coins if no yellow coins available
        const receiverOffset = await WalletService.autoOffsetGreenReceiver(receiverId);

        return {
            success: true,
            message: `Transferred ${parsedAmount} green coins from ${senderId} to ${receiverId}`,
            sender: {
                user_id: senderId,
                green_coins: parseFloat(senderWallet.green_coins),
            },
            receiver: {
                user_id: receiverId,
                green_coins: parseFloat(receiverWallet.green_coins),
                red_coins_offset: receiverOffset,
            },
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Send energy (primary P2P method — takes Rs amount).
    // Reads coin values from DB, calculates yellow to deduct and green to
    // credit, logs admin profit, calls stored procedure atomically.
    //
    //   yellow_deducted = amount_rs / yellow_value
    //   profit_rs       = amount_rs × PLATFORM_FEE
    //   green_credited  = (amount_rs − profit_rs) / green_value
    // ─────────────────────────────────────────────────────────────────────
    static async sendEnergy(sellerId, buyerId, amountRs) {
        const seller = await User.findByPk(sellerId);
        if (!seller) throw new Error('Seller not found');
        if (seller.user_type !== 'prosumer') throw new Error('Only prosumers can send energy');

        const buyer = await User.findByPk(buyerId);
        if (!buyer) throw new Error('Buyer not found');

        if (sellerId === buyerId) throw new Error('Cannot send energy to yourself');

        const parsedRs = parseFloat(amountRs);
        if (!parsedRs || parsedRs <= 0) throw new Error('Amount must be greater than 0');

        // Read coin values from DB (fallback to JS constants)
        const coinVals      = await WalletService.getCoinValues();
        const yellowVal     = coinVals.yellow_rs;               // Rs 4
        const greenVal      = coinVals.green_rs;                // Rs 7
        const yellowDeducted = parseFloat((parsedRs / yellowVal).toFixed(4));   // e.g. 1000/4 = 250
        const profitRs       = parseFloat((parsedRs * PLATFORM_FEE).toFixed(2)); // e.g. 1000×0.2 = 200
        const buyerRs        = parsedRs - profitRs;                               // e.g. 800
        const greenCredited  = parseFloat((buyerRs / greenVal).toFixed(4));       // e.g. 800/7 ≈ 114.2857

        try {
            await sequelize.query(
                'CALL sell_yellow_coins(:seller, :buyer, :yellow, :green, :gross, :profit)',
                {
                    replacements: {
                        seller: sellerId,
                        buyer:  buyerId,
                        yellow: yellowDeducted,
                        green:  greenCredited,
                        gross:  parsedRs,
                        profit: profitRs,
                    },
                    type: QueryTypes.RAW,
                }
            );
        } catch (err) {
            const sqlMessage = err.original?.sqlMessage || err.message || '';
            if (/PROCEDURE\s+.*sell_yellow_coins.*does not exist/i.test(sqlMessage)) {
                await WalletService.sellYellowCoinsFallback(
                    sellerId,
                    buyerId,
                    yellowDeducted,
                    greenCredited,
                    parsedRs,
                    profitRs
                );
            } else {
                if (sqlMessage) throw new Error(sqlMessage);
                throw err;
            }
        }

        const updatedSeller = await Wallet.findOne({ where: { user_id: sellerId } });
        const updatedBuyer  = await Wallet.findOne({ where: { user_id: buyerId } });

        // Auto-offset buyer's red coins with green coins if no yellow coins available
        const buyerOffset = await WalletService.autoOffsetGreenReceiver(buyerId);

        return {
            success:          true,
            message:          `Sent Rs ${parsedRs} of energy. ${buyerId} received ${greenCredited} green coins.`,
            gross_rs:         parsedRs,
            platform_fee_rs:  profitRs,
            yellow_deducted:  yellowDeducted,
            green_credited:   greenCredited,
            seller: {
                user_id:      sellerId,
                yellow_coins: parseFloat(updatedSeller.yellow_coins),
            },
            buyer: {
                user_id:     buyerId,
                green_coins: parseFloat(updatedBuyer.green_coins),
                red_coins_offset: buyerOffset,
            },
        };
    }

    // Fallback logic when stored procedure does not exist
    static async sellYellowCoinsFallback(sellerId, buyerId, yellowAmount, greenAmount, grossRs, profitRs) {
        await sequelize.transaction(async (t) => {
            const [rows] = await sequelize.query(
                'SELECT yellow_coins FROM wallets WHERE user_id = :seller FOR UPDATE',
                {
                    replacements: { seller: sellerId },
                    transaction: t,
                }
            );

            if (!rows || rows.length === 0) {
                throw new Error('Seller wallet not found');
            }

            const sellerYellow = parseFloat(rows[0].yellow_coins);
            if (sellerYellow < yellowAmount) {
                throw new Error('Insufficient yellow coin balance');
            }

            await sequelize.query(
                'UPDATE wallets SET yellow_coins = yellow_coins - :yellow, updated_at = NOW() WHERE user_id = :seller',
                {
                    replacements: { seller: sellerId, yellow: yellowAmount },
                    transaction: t,
                }
            );

            await sequelize.query(
                'UPDATE wallets SET green_coins = green_coins + :green, updated_at = NOW() WHERE user_id = :buyer',
                {
                    replacements: { buyer: buyerId, green: greenAmount },
                    transaction: t,
                }
            );

            await sequelize.query(
                `INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, amount_rs, transaction_type, note, status)
                 VALUES (:seller, :buyer, 'yellow', :yellow, :gross, 'sale', :sale_note, 'completed')`,
                {
                    replacements: {
                        seller: sellerId,
                        buyer: buyerId,
                        yellow: yellowAmount,
                        gross: grossRs,
                        sale_note: `Sent Rs ${grossRs} of energy (${yellowAmount} yellow coins)`,
                    },
                    transaction: t,
                }
            );

            await sequelize.query(
                `INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, amount_rs, transaction_type, note, status)
                 VALUES (:seller, :buyer, 'green', :green, :net, 'purchase', :purchase_note, 'completed')`,
                {
                    replacements: {
                        seller: sellerId,
                        buyer: buyerId,
                        green: greenAmount,
                        net: grossRs - profitRs,
                        purchase_note: `Received Rs ${grossRs - profitRs} of energy (${greenAmount} green coins)`,
                    },
                    transaction: t,
                }
            );

            await sequelize.query(
                'INSERT INTO admin_profit (seller_id, buyer_id, yellow_sold, gross_rs, profit_rs, buyer_green) VALUES (:seller, :buyer, :yellow, :gross, :profit, :green)',
                {
                    replacements: {
                        seller: sellerId,
                        buyer: buyerId,
                        yellow: yellowAmount,
                        gross: grossRs,
                        profit: profitRs,
                        green: greenAmount,
                    },
                    transaction: t,
                }
            );
        });
    }

    // ─────────────────────────────────────────────────────────────────────
    // Sell yellow coins (legacy — takes yellow coin count; delegates to sendEnergy)
    // ─────────────────────────────────────────────────────────────────────
    static async sellYellowCoins(sellerId, buyerId, yellowAmount) {
        const parsedYellow = parseFloat(yellowAmount);
        if (!parsedYellow || parsedYellow <= 0) throw new Error('Amount must be greater than 0');

        const coinVals = await WalletService.getCoinValues();
        const amountRs = parsedYellow * coinVals.yellow_rs;
        return WalletService.sendEnergy(sellerId, buyerId, amountRs);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Manual offset: cancel up to `amount` red coins using yellow first,
    // then green for any remainder. Throws if combined balance is insufficient.
    // ─────────────────────────────────────────────────────────────────────
    static async offsetRed(userId, amount) {
        const parsedAmount = parseFloat(amount);
        if (!parsedAmount || parsedAmount <= 0) {
            throw new Error('Amount must be greater than 0');
        }

        const wallet = await Wallet.findOne({ where: { user_id: userId } });
        if (!wallet) throw new Error('Wallet not found');

        const yellow = parseFloat(wallet.yellow_coins) || 0;
        const green  = parseFloat(wallet.green_coins)  || 0;
        const red    = parseFloat(wallet.red_coins)    || 0;

        if (parsedAmount > red) throw new Error('Offset amount exceeds red coin balance');
        if (yellow + green < parsedAmount) throw new Error('Insufficient yellow + green coins to offset');

        let remaining = parsedAmount;

        // Step 1: use yellow first
        const yellowOffset = Math.min(yellow, remaining);
        if (yellowOffset > 0) {
            await sequelize.query(
                'CALL offset_red_with_yellow(:userId, :amount)',
                { replacements: { userId, amount: yellowOffset }, type: QueryTypes.RAW }
            );
            remaining -= yellowOffset;
        }

        // Step 2: use green for remainder
        if (remaining > 0) {
            await sequelize.query(
                'CALL offset_red_with_green(:userId, :amount)',
                { replacements: { userId, amount: remaining }, type: QueryTypes.RAW }
            );
        }

        const updated = await Wallet.findOne({ where: { user_id: userId } });
        return {
            success: true,
            message: `Offset ${parsedAmount} red coins (yellow: ${yellowOffset.toFixed(4)}, green: ${(parsedAmount - yellowOffset).toFixed(4)})`,
            user_id: userId,
            yellow_coins: parseFloat(updated.yellow_coins),
            green_coins:  parseFloat(updated.green_coins),
            red_coins:    parseFloat(updated.red_coins),
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Auto-offset: reduce red debt using yellow first, then green for remainder.
    // Returns total amount offset (0 if nothing to offset).
    // Called after yellow coins are minted each billing cycle.
    // ─────────────────────────────────────────────────────────────────────
    static async autoOffset(userId) {
        const wallet = await Wallet.findOne({ where: { user_id: userId } });
        if (!wallet) return 0;

        let yellow = parseFloat(wallet.yellow_coins) || 0;
        let green  = parseFloat(wallet.green_coins)  || 0;
        let red    = parseFloat(wallet.red_coins)    || 0;

        if (red <= 0 || (yellow <= 0 && green <= 0)) return 0;

        let totalOffset = 0;

        // Step 1: offset with yellow first
        const yellowOffset = Math.min(yellow, red);
        if (yellowOffset > 0) {
            await sequelize.query(
                `UPDATE wallets
                 SET yellow_coins = yellow_coins - :offset,
                     red_coins    = red_coins    - :offset,
                     updated_at   = CURRENT_TIMESTAMP
                 WHERE user_id = :userId`,
                { replacements: { offset: yellowOffset, userId } }
            );
            await sequelize.query(
                `INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, note, status)
                 VALUES (:userId, NULL, 'yellow', :offset, 'offset', 'Auto-offset: yellow coins applied against red debt', 'completed')`,
                { replacements: { userId, offset: yellowOffset } }
            );
            yellow     -= yellowOffset;
            red        -= yellowOffset;
            totalOffset += yellowOffset;
        }

        // Step 2: offset remaining red with green
        const greenOffset = Math.min(green, red);
        if (greenOffset > 0) {
            await sequelize.query(
                `UPDATE wallets
                 SET green_coins = green_coins - :offset,
                     red_coins   = red_coins   - :offset,
                     updated_at  = CURRENT_TIMESTAMP
                 WHERE user_id = :userId`,
                { replacements: { offset: greenOffset, userId } }
            );
            await sequelize.query(
                `INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, note, status)
                 VALUES (:userId, NULL, 'green', :offset, 'offset', 'Auto-offset: green coins applied against remaining red debt', 'completed')`,
                { replacements: { userId, offset: greenOffset } }
            );
            totalOffset += greenOffset;
        }

        return totalOffset;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Auto-offset for green coin receivers: offset red debt using green coins
    // only if user has no yellow coins. Called when green coins are received.
    // Returns total amount offset (0 if nothing to offset or has yellow coins).
    // ─────────────────────────────────────────────────────────────────────
    static async autoOffsetGreenReceiver(userId) {
        const wallet = await Wallet.findOne({ where: { user_id: userId } });
        if (!wallet) return 0;

        let yellow = parseFloat(wallet.yellow_coins) || 0;
        let green  = parseFloat(wallet.green_coins)  || 0;
        let red    = parseFloat(wallet.red_coins)    || 0;

        // Only offset if user has no yellow coins, has green coins, and has red debt
        if (yellow > 0 || green <= 0 || red <= 0) return 0;

        // Offset red debt with green coins
        const offsetAmount = Math.min(green, red);

        if (offsetAmount > 0) {
            await sequelize.query(
                `UPDATE wallets
                 SET green_coins = green_coins - :offset,
                     red_coins   = red_coins   - :offset,
                     updated_at  = CURRENT_TIMESTAMP
                 WHERE user_id = :userId`,
                { replacements: { offset: offsetAmount, userId } }
            );
            await sequelize.query(
                `INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, note, status)
                 VALUES (:userId, NULL, 'green', :offset, 'offset', 'Auto-offset: green coins applied against red debt (no yellow coins available)', 'completed')`,
                { replacements: { userId, offset: offsetAmount } }
            );
        }

        return offsetAmount;
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