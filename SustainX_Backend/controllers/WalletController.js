const WalletService = require('../services/WalletService');

class WalletController {
    // Get wallet information
    static async getWallet(req, res, next) {
        try {
            const userId = req.userId;

            const wallet = await WalletService.getWallet(userId);

            return res.status(200).json({
                success: true,
                data: wallet
            });
        } catch (err) {
            next(err);
        }
    }

    // Get wallet balance
    static async getBalance(req, res, next) {
        try {
            const userId = req.userId;

            const balance = await WalletService.getWalletBalance(userId);

            return res.status(200).json({
                success: true,
                data: balance
            });
        } catch (err) {
            next(err);
        }
    }

    // Generate QR code
    static async generateQRCode(req, res, next) {
        try {
            const userId = req.userId;

            const qrCode = await WalletService.generateQRCode(userId);

            return res.status(200).json({
                success: true,
                data: qrCode
            });
        } catch (err) {
            next(err);
        }
    }

    // Get leaderboard
    static async getLeaderboard(req, res, next) {
        try {
            const { limit = 10 } = req.query;

            const leaderboard = await WalletService.getLeaderboard(parseInt(limit));

            return res.status(200).json({
                success: true,
                data: leaderboard
            });
        } catch (err) {
            next(err);
        }
    }

    // Get leaderboard by total coins
    static async getLeaderboardByCoins(req, res, next) {
        try {
            const { limit = 10 } = req.query;

            const leaderboard = await WalletService.getLeaderboardByCoins(parseInt(limit));

            return res.status(200).json({
                success: true,
                data: leaderboard
            });
        } catch (err) {
            next(err);
        }
    }

    // Get user rank
    static async getUserRank(req, res, next) {
        try {
            const userId = req.userId;

            const rank = await WalletService.getUserRank(userId);

            return res.status(200).json({
                success: true,
                data: rank
            });
        } catch (err) {
            next(err);
        }
    }

    // Get wallet address
    static async getWalletAddress(req, res, next) {
        try {
            const userId = req.userId;

            const address = await WalletService.getWalletAddress(userId);

            return res.status(200).json({
                success: true,
                data: address
            });
        } catch (err) {
            next(err);
        }
    }
}

module.exports = WalletController;
