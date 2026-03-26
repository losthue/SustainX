const User = require('../models/User');
const QRCode = require('qrcode');

class WalletService {
    static async getWallet(userId) {
        const user = await User.findByPk(userId);
        if (!user) throw new Error('User not found');
        return user.getWalletInfo();
    }

    static async getWalletBalance(userId) {
        const user = await User.findByPk(userId);
        if (!user) throw new Error('User not found');

        return {
            userId: user.id,
            username: user.username,
            balances: {
                yellowCoins: user.yellowCoins,
                greenCoins: user.greenCoins,
                redCoins: user.redCoins,
            },
            totalBalance: user.getTotalBalance(),
            energyScore: user.energyScore,
            walletAddress: user.walletAddress,
        };
    }

    static async generateQRCode(userId) {
        const user = await User.findByPk(userId);
        if (!user) throw new Error('User not found');

        try {
            const walletData = {
                walletAddress: user.walletAddress,
                userId: user.id,
                username: user.username,
                timestamp: Date.now(),
            };

            const qrCodeUrl = await QRCode.toDataURL(JSON.stringify(walletData));

            return {
                success: true,
                qrCodeUrl,
                walletAddress: user.walletAddress,
                username: user.username,
            };
        } catch (err) {
            throw new Error(`Failed to generate QR code: ${err.message}`);
        }
    }

    static async getLeaderboard(limit = 10) {
        const users = await User.findAll({
            order: [['energyScore', 'DESC']],
            limit,
            attributes: ['id', 'username', 'energyScore', 'yellowCoins', 'greenCoins', 'redCoins', 'profileImage', 'walletAddress'],
        });

        return users.map((user, index) => ({
            rank: index + 1,
            username: user.username,
            energyScore: user.energyScore,
            balances: {
                yellowCoins: user.yellowCoins,
                greenCoins: user.greenCoins,
                redCoins: user.redCoins,
            },
            totalBalance: user.getTotalBalance(),
            profileImage: user.profileImage,
        }));
    }

    static async getLeaderboardByCoins(limit = 10) {
        const users = await User.findAll({
            attributes: ['id', 'username', 'energyScore', 'yellowCoins', 'greenCoins', 'redCoins', 'profileImage'],
        });

        const leaderboard = users
            .map((user) => {
                const totalCoins = user.getTotalBalance();
                return {
                    username: user.username,
                    totalCoins,
                    yellowCoins: user.yellowCoins,
                    greenCoins: user.greenCoins,
                    redCoins: user.redCoins,
                    energyScore: user.energyScore,
                    profileImage: user.profileImage,
                };
            })
            .sort((a, b) => b.totalCoins - a.totalCoins)
            .slice(0, limit)
            .map((user, index) => ({ rank: index + 1, ...user }));

        return leaderboard;
    }

    static async getUserRank(userId) {
        const user = await User.findByPk(userId);
        if (!user) throw new Error('User not found');

        const rank = await User.count({
            where: { energyScore: { [require('sequelize').Op.gt]: user.energyScore } },
        });

        const totalUsers = await User.count();

        return {
            username: user.username,
            rank: rank + 1,
            energyScore: user.energyScore,
            totalCoins: user.getTotalBalance(),
            percentile: totalUsers ? ((rank + 1) / totalUsers) * 100 : 0,
        };
    }

    static async updateWalletBalance(userId, yellowCoins = 0, greenCoins = 0, redCoins = 0) {
        const user = await User.findByPk(userId);
        if (!user) throw new Error('User not found');

        user.yellowCoins += yellowCoins;
        user.greenCoins += greenCoins;
        user.redCoins += redCoins;

        await user.save();

        return user.getWalletInfo();
    }

    static async getWalletAddress(userId) {
        const user = await User.findByPk(userId);
        if (!user) throw new Error('User not found');

        return {
            walletAddress: user.walletAddress,
            username: user.username,
            userId: user.id,
        };
    }
}

module.exports = WalletService;
