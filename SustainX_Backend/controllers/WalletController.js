const WalletService = require('../services/WalletService');

class WalletController {

    // GET /wallet/info
    static async getWallet(req, res, next) {
        try {
            const wallet = await WalletService.getWallet(req.userId);
            return res.status(200).json({ success: true, data: wallet });
        } catch (err) { next(err); }
    }

    // GET /wallet/balance
    static async getBalance(req, res, next) {
        try {
            const balance = await WalletService.getWalletBalance(req.userId);
            return res.status(200).json({ success: true, data: balance });
        } catch (err) { next(err); }
    }

    // GET /wallet/coin-values
    static async getCoinValues(_req, res, next) {
        try {
            const data = await WalletService.getCoinValues();
            return res.status(200).json({ success: true, data });
        } catch (err) { next(err); }
    }

    // POST /wallet/send-energy
    // Body: { buyer_id: string, amount_rs: number }
    // Prosumer sends Rs X of energy: yellow deducted from sender,
    // green credited to buyer, difference goes to admin profit.
    static async sendEnergy(req, res, next) {
        try {
            const { buyer_id, amount_rs } = req.body;
            if (!buyer_id) return res.status(400).json({ success: false, message: 'buyer_id is required' });
            if (!amount_rs || parseFloat(amount_rs) <= 0) return res.status(400).json({ success: false, message: 'Provide a positive Rs amount' });

            const result = await WalletService.sendEnergy(req.userId, buyer_id, parseFloat(amount_rs));
            return res.status(200).json({ success: true, data: result });
        } catch (err) { next(err); }
    }

    // POST /wallet/sell-yellow
    // Body: { buyer_id: string, amount: number }  (amount = yellow coin count)
    static async sellYellow(req, res, next) {
        try {
            const { buyer_id, amount } = req.body;
            if (!buyer_id) return res.status(400).json({ success: false, message: 'buyer_id is required' });
            if (!amount || parseFloat(amount) <= 0) return res.status(400).json({ success: false, message: 'Provide a positive amount to sell' });

            const result = await WalletService.sellYellowCoins(req.userId, buyer_id, parseFloat(amount));
            return res.status(200).json({ success: true, data: result });
        } catch (err) { next(err); }
    }

    // POST /wallet/transfer-green
    // Body: { receiver_id: string, amount: number, note?: string }
    static async transferGreen(req, res, next) {
        try {
            const { receiver_id, amount, note } = req.body;

            if (!receiver_id) {
                return res.status(400).json({
                    success: false,
                    message: 'receiver_id is required',
                });
            }
            if (!amount || parseFloat(amount) <= 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Provide a positive amount to transfer',
                });
            }

            const result = await WalletService.transferGreenCoins(
                req.userId,
                receiver_id,
                parseFloat(amount),
                note
            );
            return res.status(200).json({ success: true, data: result });
        } catch (err) { next(err); }
    }

    // POST /wallet/offset-red
    // Body: { amount: number }
    static async offsetRed(req, res, next) {
        try {
            const { amount } = req.body;

            if (!amount || parseFloat(amount) <= 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Provide a positive amount to offset',
                });
            }

            const result = await WalletService.offsetRed(req.userId, parseFloat(amount));
            return res.status(200).json({ success: true, data: result });
        } catch (err) { next(err); }
    }

    // GET /wallet/leaderboard?limit=10
    static async getLeaderboard(req, res, next) {
        try {
            const { limit = 10 } = req.query;
            const leaderboard = await WalletService.getLeaderboard(parseInt(limit));
            return res.status(200).json({ success: true, data: leaderboard });
        } catch (err) { next(err); }
    }

    // GET /wallet/system-totals
    static async getSystemTotals(_req, res, next) {
        try {
            const totals = await WalletService.getSystemTotals();
            return res.status(200).json({ success: true, data: totals });
        } catch (err) { next(err); }
    }
}

module.exports = WalletController;